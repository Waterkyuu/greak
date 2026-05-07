import gleam/list
import gleam/option.{None, Some}
import gleam/result

import greak/core/error.{type RuntimeError, describe}
import greak/core/event.{
  type RunEvent, RequestBuilt, ResponseDelta, ResponseStarted, RunCompleted,
  RunFailed, RunStarted, ToolCallCompleted, ToolCallRequested, UsageUpdated,
}
import greak/core/message.{
  type AgentResult, type InputItem, type ToolCall, AgentResult,
  FunctionCallOutput, UserText,
}
import greak/core/usage as runtime_usage
import greak/model/provider.{
  type Provider, type ProviderRequest, ProviderRequest, invoke, invoke_stream,
}
import greak/tool/registry.{type ToolRegistry, execute, to_list}

pub type ReactConfig {
  ReactConfig(provider: Provider, system_prompt: String, stream: Bool)
}

pub fn new(
  provider: Provider,
  system_prompt: String,
  stream: Bool,
) -> ReactConfig {
  ReactConfig(provider:, system_prompt:, stream:)
}

pub fn run(
  config: ReactConfig,
  tools: ToolRegistry,
  user_input: String,
  emit: fn(RunEvent) -> Nil,
) -> Result(AgentResult, RuntimeError) {
  emit(RunStarted)

  let request =
    ProviderRequest(
      instructions: config.system_prompt,
      input: [UserText(user_input)],
      tools: to_list(tools),
      previous_response_id: None,
    )

  case loop(config, tools, request, runtime_usage.new(), emit) {
    Ok(result) -> Ok(result)
    Error(error) -> {
      emit(RunFailed(describe(error)))
      Error(error)
    }
  }
}

fn loop(
  config: ReactConfig,
  tools: ToolRegistry,
  request: ProviderRequest,
  accumulated_usage: runtime_usage.Usage,
  emit: fn(RunEvent) -> Nil,
) -> Result(AgentResult, RuntimeError) {
  emit(RequestBuilt(config.stream))
  emit(ResponseStarted)

  let provider_response = case config.stream {
    True ->
      invoke_stream(config.provider, request, fn(chunk) {
        emit(ResponseDelta(chunk))
      })
    False -> invoke(config.provider, request)
  }

  use provider_response <- result.try(provider_response)

  case !config.stream && provider_response.output_text != "" {
    True -> emit(ResponseDelta(provider_response.output_text))
    False -> Nil
  }

  let accumulated_usage =
    runtime_usage.merge(accumulated_usage, provider_response.usage)
  emit(UsageUpdated(accumulated_usage))

  case provider_response.tool_calls {
    [] -> {
      emit(RunCompleted(
        output_text: provider_response.output_text,
        usage: accumulated_usage,
      ))
      Ok(AgentResult(
        output_text: provider_response.output_text,
        usage: accumulated_usage,
      ))
    }
    tool_calls -> {
      use next_input <- result.try(execute_tool_calls(tool_calls, tools, emit))
      let next_request =
        ProviderRequest(
          instructions: config.system_prompt,
          input: next_input,
          tools: request.tools,
          previous_response_id: Some(provider_response.response_id),
        )

      loop(config, tools, next_request, accumulated_usage, emit)
    }
  }
}

fn execute_tool_calls(
  tool_calls: List(ToolCall),
  tools: ToolRegistry,
  emit: fn(RunEvent) -> Nil,
) -> Result(List(InputItem), RuntimeError) {
  result.all(
    tool_calls
    |> list.map(fn(tool_call) {
      emit(ToolCallRequested(tool_call))

      case execute(tools, tool_call.name, tool_call.arguments_json) {
        Ok(result_json) -> {
          emit(ToolCallCompleted(
            call_id: tool_call.call_id,
            name: tool_call.name,
            result_json: result_json,
          ))
          Ok(FunctionCallOutput(call_id: tool_call.call_id, output: result_json))
        }
        Error(error) -> Error(error)
      }
    }),
  )
}
