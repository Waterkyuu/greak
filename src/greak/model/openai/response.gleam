import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json
import gleam/list

import greak/core/error.{type RuntimeError, ResponseDecodeFailed}
import greak/core/message.{type ToolCall, ToolCall}
import greak/core/usage as runtime_usage
import greak/model/provider.{type ProviderResponse, ProviderResponse}

pub fn decode_output(
  json_string: String,
) -> Result(ProviderResponse, RuntimeError) {
  decode_with(json_string, response_decoder())
}

pub fn decode_completed_event(
  json_string: String,
) -> Result(ProviderResponse, RuntimeError) {
  decode_with(json_string, completed_event_decoder())
}

pub fn decode_output_text_delta_event(
  json_string: String,
) -> Result(String, RuntimeError) {
  decode_with(json_string, output_text_delta_decoder())
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
    use output_text <- decode.optional_field("output_text", "", decode.string)
    use usage <- decode.optional_field(
      "usage",
      runtime_usage.new(),
      usage_decoder(),
    )
    use output <- decode.optional_field(
      "output",
      [],
      decode.list(of: dynamic_decoder()),
    )

    decode.success(ProviderResponse(
      response_id: response_id,
      output_text: output_text,
      tool_calls: collect_tool_calls(output),
      usage: usage,
    ))
  }
}

fn completed_event_decoder() -> decode.Decoder(ProviderResponse) {
  {
    use event_type <- decode.field("type", decode.string)

    case event_type {
      "response.completed" -> decode.at(["response"], response_decoder())
      _ ->
        decode.failure(
          ProviderResponse(
            response_id: "",
            output_text: "",
            tool_calls: [],
            usage: runtime_usage.new(),
          ),
          expected: "response.completed",
        )
    }
  }
}

fn output_text_delta_decoder() -> decode.Decoder(String) {
  {
    use event_type <- decode.field("type", decode.string)

    case event_type {
      "response.output_text.delta" -> decode.at(["delta"], decode.string)
      _ -> decode.failure("", expected: "response.output_text.delta")
    }
  }
}

fn usage_decoder() -> decode.Decoder(runtime_usage.Usage) {
  {
    use input_tokens <- decode.optional_field("input_tokens", 0, decode.int)
    use output_tokens <- decode.optional_field("output_tokens", 0, decode.int)
    decode.success(runtime_usage.add(
      runtime_usage.new(),
      input_tokens: input_tokens,
      output_tokens: output_tokens,
    ))
  }
}

fn collect_tool_calls(items: List(Dynamic)) -> List(ToolCall) {
  list.fold(over: items, from: [], with: fn(acc, item) {
    case decode.run(item, function_call_decoder()) {
      Ok(tool_call) -> [tool_call, ..acc]
      Error(_) -> acc
    }
  })
  |> list.reverse
}

fn function_call_decoder() -> decode.Decoder(ToolCall) {
  {
    use item_type <- decode.field("type", decode.string)

    case item_type {
      "function_call" -> {
        use call_id <- decode.field("call_id", decode.string)
        use name <- decode.field("name", decode.string)
        use arguments_json <- decode.optional_field(
          "arguments",
          "{}",
          decode.string,
        )
        decode.success(ToolCall(
          call_id: call_id,
          name: name,
          arguments_json: arguments_json,
        ))
      }
      _ ->
        decode.failure(
          ToolCall(call_id: "", name: "", arguments_json: "{}"),
          expected: "function_call",
        )
    }
  }
}

fn dynamic_decoder() -> decode.Decoder(Dynamic) {
  decode.new_primitive_decoder("Dynamic", fn(data) { Ok(data) })
}
