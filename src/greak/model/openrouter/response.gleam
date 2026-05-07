import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/result

import greak/core/error.{type RuntimeError, ResponseDecodeFailed}
import greak/core/message.{type ToolCall, ToolCall}
import greak/core/usage as runtime_usage
import greak/model/provider.{type ProviderResponse, ProviderResponse}

pub type StreamState {
  StreamState(
    response_id: String,
    output_text: String,
    tool_calls: Dict(Int, ToolCall),
    usage: runtime_usage.Usage,
  )
}

pub type StreamDelta {
  StreamDelta(
    response_id: String,
    content_delta: String,
    tool_calls: List(ToolCallDelta),
    usage: runtime_usage.Usage,
  )
}

pub type ToolCallDelta {
  ToolCallDelta(
    index: Int,
    call_id: String,
    name: String,
    arguments_piece: String,
  )
}

pub fn decode_output(
  json_string: String,
) -> Result(ProviderResponse, RuntimeError) {
  decode_with(json_string, response_decoder())
}

pub fn decode_stream_delta(
  json_string: String,
) -> Result(StreamDelta, RuntimeError) {
  decode_with(json_string, stream_delta_decoder())
}

pub fn new_stream_state() -> StreamState {
  StreamState(
    response_id: "",
    output_text: "",
    tool_calls: dict.new(),
    usage: runtime_usage.new(),
  )
}

pub fn apply_stream_delta(
  state: StreamState,
  delta: StreamDelta,
) -> StreamState {
  let tool_calls =
    list.fold(
      over: delta.tool_calls,
      from: state.tool_calls,
      with: fn(acc, tool_call_delta) {
        let existing =
          dict.get(acc, tool_call_delta.index)
          |> result.unwrap(ToolCall(call_id: "", name: "", arguments_json: ""))

        let merged =
          ToolCall(
            call_id: merge_string(existing.call_id, tool_call_delta.call_id),
            name: merge_string(existing.name, tool_call_delta.name),
            arguments_json: existing.arguments_json
              <> tool_call_delta.arguments_piece,
          )

        dict.insert(acc, tool_call_delta.index, merged)
      },
    )

  StreamState(
    response_id: merge_string(state.response_id, delta.response_id),
    output_text: state.output_text <> delta.content_delta,
    tool_calls: tool_calls,
    usage: runtime_usage.merge(state.usage, delta.usage),
  )
}

pub fn finalize_stream_state(state: StreamState) -> ProviderResponse {
  let ordered_tool_calls =
    state.tool_calls
    |> dict.to_list
    |> list.sort(fn(left, right) { int.compare(left.0, right.0) })
    |> list.map(fn(entry) { entry.1 })

  ProviderResponse(
    response_id: state.response_id,
    output_text: state.output_text,
    tool_calls: ordered_tool_calls,
    usage: state.usage,
  )
}

fn decode_with(
  json_string: String,
  decoder: decode.Decoder(t),
) -> Result(t, RuntimeError) {
  case json.parse(from: json_string, using: decoder) {
    Ok(value) -> Ok(value)
    Error(_errors) ->
      Error(ResponseDecodeFailed("unable to parse provider payload"))
  }
}

fn response_decoder() -> decode.Decoder(ProviderResponse) {
  {
    use response_id <- decode.field("id", decode.string)
    use usage <- decode.optional_field(
      "usage",
      runtime_usage.new(),
      usage_decoder(),
    )
    use choices <- decode.field("choices", decode.list(of: dynamic_decoder()))

    let choice = first_dynamic(choices)
    let output_text = decode_choice_content(choice)
    let tool_calls = decode_choice_tool_calls(choice)

    decode.success(ProviderResponse(
      response_id: response_id,
      output_text: output_text,
      tool_calls: tool_calls,
      usage: usage,
    ))
  }
}

fn stream_delta_decoder() -> decode.Decoder(StreamDelta) {
  {
    use response_id <- decode.optional_field("id", "", decode.string)
    use usage <- decode.optional_field(
      "usage",
      runtime_usage.new(),
      usage_decoder(),
    )
    use choices <- decode.field("choices", decode.list(of: dynamic_decoder()))

    let choice = first_dynamic(choices)
    let content_delta = decode_choice_delta_content(choice)
    let tool_calls = decode_choice_delta_tool_calls(choice)

    decode.success(StreamDelta(
      response_id: response_id,
      content_delta: content_delta,
      tool_calls: tool_calls,
      usage: usage,
    ))
  }
}

fn usage_decoder() -> decode.Decoder(runtime_usage.Usage) {
  {
    use input_tokens <- decode.optional_field("prompt_tokens", 0, decode.int)
    use output_tokens <- decode.optional_field(
      "completion_tokens",
      0,
      decode.int,
    )
    decode.success(runtime_usage.add(
      runtime_usage.new(),
      input_tokens: input_tokens,
      output_tokens: output_tokens,
    ))
  }
}

fn decode_choice_content(choice: Dynamic) -> String {
  let decoder = decode.at(["message", "content"], decode.string)
  decode.run(choice, decoder)
  |> result.unwrap("")
}

fn decode_choice_tool_calls(choice: Dynamic) -> List(ToolCall) {
  let decoder =
    decode.at(["message", "tool_calls"], decode.list(of: dynamic_decoder()))

  case decode.run(choice, decoder) {
    Ok(items) ->
      list.fold(over: items, from: [], with: fn(acc, item) {
        case decode.run(item, tool_call_decoder()) {
          Ok(tool_call) -> [tool_call, ..acc]
          Error(_) -> acc
        }
      })
      |> list.reverse
    Error(_) -> []
  }
}

fn decode_choice_delta_content(choice: Dynamic) -> String {
  let decoder = decode.at(["delta", "content"], decode.string)
  decode.run(choice, decoder)
  |> result.unwrap("")
}

fn decode_choice_delta_tool_calls(choice: Dynamic) -> List(ToolCallDelta) {
  let decoder =
    decode.at(["delta", "tool_calls"], decode.list(of: dynamic_decoder()))

  case decode.run(choice, decoder) {
    Ok(items) ->
      list.fold(over: items, from: [], with: fn(acc, item) {
        case decode.run(item, tool_call_delta_decoder()) {
          Ok(tool_call_delta) -> [tool_call_delta, ..acc]
          Error(_) -> acc
        }
      })
      |> list.reverse
    Error(_) -> []
  }
}

fn tool_call_decoder() -> decode.Decoder(ToolCall) {
  {
    use call_id <- decode.field("id", decode.string)
    use function_data <- decode.field("function", function_decoder())
    let #(name, arguments_json) = function_data
    decode.success(ToolCall(
      call_id: call_id,
      name: name,
      arguments_json: arguments_json,
    ))
  }
}

fn tool_call_delta_decoder() -> decode.Decoder(ToolCallDelta) {
  {
    use index <- decode.field("index", decode.int)
    use call_id <- decode.optional_field("id", "", decode.string)
    use function_data <- decode.optional_field(
      "function",
      #("", ""),
      function_delta_decoder(),
    )
    let #(name, arguments_piece) = function_data
    decode.success(ToolCallDelta(
      index: index,
      call_id: call_id,
      name: name,
      arguments_piece: arguments_piece,
    ))
  }
}

fn dynamic_decoder() -> decode.Decoder(Dynamic) {
  decode.new_primitive_decoder("Dynamic", fn(data) { Ok(data) })
}

fn function_decoder() -> decode.Decoder(#(String, String)) {
  {
    use name <- decode.field("name", decode.string)
    use arguments_json <- decode.field("arguments", decode.string)
    decode.success(#(name, arguments_json))
  }
}

fn function_delta_decoder() -> decode.Decoder(#(String, String)) {
  {
    use name <- decode.optional_field("name", "", decode.string)
    use arguments_piece <- decode.optional_field("arguments", "", decode.string)
    decode.success(#(name, arguments_piece))
  }
}

fn first_dynamic(items: List(Dynamic)) -> Dynamic {
  case items {
    [first, ..] -> first
    [] -> panic as "expected at least one choice"
  }
}

fn merge_string(current: String, update: String) -> String {
  case update == "" {
    True -> current
    False -> update
  }
}
