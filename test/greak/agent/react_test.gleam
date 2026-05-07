import gleam/option.{None, Some}

import greak/agent/react
import greak/core/error
import greak/core/message.{ToolCall}
import greak/core/usage
import greak/model/provider
import greak/tool/definition
import greak/tool/registry

pub fn react_executes_tool_call_test() {
  let fake_provider =
    provider.new(
      conversation_mode: provider.StatefulConversation,
      invoke: fn(request) {
        case request.previous_response_id {
          None ->
            Ok(provider.ProviderResponse(
              response_id: "resp_1",
              output_text: "",
              tool_calls: [
                ToolCall(
                  call_id: "call_1",
                  name: "echo",
                  arguments_json: "{\"value\":\"hi\"}",
                ),
              ],
              usage: usage.add(usage.new(), input_tokens: 10, output_tokens: 2),
            ))
          Some(_) ->
            Ok(provider.ProviderResponse(
              response_id: "resp_2",
              output_text: "hi",
              tool_calls: [],
              usage: usage.add(usage.new(), input_tokens: 3, output_tokens: 1),
            ))
        }
      },
      invoke_stream: fn(request, _) {
        case request.previous_response_id {
          None ->
            Ok(provider.ProviderResponse(
              response_id: "resp_1",
              output_text: "",
              tool_calls: [
                ToolCall(
                  call_id: "call_1",
                  name: "echo",
                  arguments_json: "{\"value\":\"hi\"}",
                ),
              ],
              usage: usage.add(usage.new(), input_tokens: 10, output_tokens: 2),
            ))
          Some(_) ->
            Ok(provider.ProviderResponse(
              response_id: "resp_2",
              output_text: "hi",
              tool_calls: [],
              usage: usage.add(usage.new(), input_tokens: 3, output_tokens: 1),
            ))
        }
      },
    )

  let tool =
    definition.new(
      name: "echo",
      description: "Echoes",
      parameters_json_schema: "{\"type\":\"object\"}",
      execute: fn(_) { Ok("hi") },
    )

  let agent = react.new(fake_provider, "You are helpful.", False)
  let registry = registry.from_list([tool])

  let assert Ok(result) =
    react.run(agent, registry, "Use the echo tool", fn(_) { Nil })

  assert result.output_text == "hi"
  assert result.usage.total_tokens == 16
}

pub fn react_replays_tool_history_for_stateless_provider_test() {
  let sync_invoke = fn(request: provider.ProviderRequest) {
    case request.previous_response_id, request.input {
      None, [_, _, _] ->
        Ok(provider.ProviderResponse(
          response_id: "resp_2",
          output_text: "stateless-ok",
          tool_calls: [],
          usage: usage.add(usage.new(), input_tokens: 2, output_tokens: 1),
        ))
      None, _ ->
        Ok(provider.ProviderResponse(
          response_id: "resp_1",
          output_text: "",
          tool_calls: [
            ToolCall(
              call_id: "call_1",
              name: "echo",
              arguments_json: "{\"value\":\"hi\"}",
            ),
          ],
          usage: usage.add(usage.new(), input_tokens: 10, output_tokens: 2),
        ))
      Some(_), _ ->
        Ok(provider.ProviderResponse(
          response_id: "resp_2",
          output_text: "stateless-ok",
          tool_calls: [],
          usage: usage.add(usage.new(), input_tokens: 2, output_tokens: 1),
        ))
    }
  }

  let fake_provider =
    provider.new(
      conversation_mode: provider.StatelessConversation,
      invoke: sync_invoke,
      invoke_stream: fn(request, _) { sync_invoke(request) },
    )

  let tool =
    definition.new(
      name: "echo",
      description: "Echoes",
      parameters_json_schema: "{\"type\":\"object\"}",
      execute: fn(_) { Ok("hi") },
    )

  let agent = react.new(fake_provider, "You are helpful.", False)
  let tools = registry.from_list([tool])

  let assert Ok(result) =
    react.run(agent, tools, "Use the echo tool", fn(_) { Nil })

  assert result.output_text == "stateless-ok"
}

pub fn react_stops_when_max_iterations_is_exceeded_test() {
  let sync_invoke = fn(_) {
    Ok(provider.ProviderResponse(
      response_id: "resp_loop",
      output_text: "",
      tool_calls: [
        ToolCall(
          call_id: "call_loop",
          name: "echo",
          arguments_json: "{\"value\":\"loop\"}",
        ),
      ],
      usage: usage.add(usage.new(), input_tokens: 1, output_tokens: 1),
    ))
  }

  let fake_provider =
    provider.new(
      conversation_mode: provider.StatefulConversation,
      invoke: sync_invoke,
      invoke_stream: fn(request, _) { sync_invoke(request) },
    )

  let tool =
    definition.new(
      name: "echo",
      description: "Echoes",
      parameters_json_schema: "{\"type\":\"object\"}",
      execute: fn(_) { Ok("loop") },
    )

  let agent =
    react.new(fake_provider, "You are helpful.", False)
    |> react.with_max_iterations(1)
  let tools = registry.from_list([tool])

  assert react.run(agent, tools, "Keep looping", fn(_) { Nil })
    == Error(error.MaxIterationsExceeded(1))
}
