import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option}

import greak/core/error
import greak/core/event

@external(erlang, "greak_cli_runtime_ffi", "arguments")
pub fn arguments() -> List(String)

@external(erlang, "greak_cli_runtime_ffi", "get_env")
pub fn get_env(name: String) -> Option(String)

pub fn print_event(run_event: event.RunEvent) -> Nil {
  case run_event {
    event.RunStarted -> io.println("[run] started")
    event.RequestBuilt(streaming) ->
      io.println("[request] built (" <> mode_label(streaming) <> ")")
    event.ResponseStarted -> io.println("[response] started")
    event.ResponseDelta(chunk) -> io.println("[delta] " <> chunk)
    event.ToolCallRequested(tool_call) ->
      io.println(
        "[tool] request " <> tool_call.name <> " " <> tool_call.arguments_json,
      )
    event.ToolCallCompleted(call_id: _, name: name, result_json: result_json) ->
      io.println("[tool] result " <> name <> " " <> result_json)
    event.PlanProduced(steps: steps) ->
      io.println("[plan] " <> int.to_string(list.length(steps)) <> " steps")
    event.UsageUpdated(usage: usage) ->
      io.println(
        "[usage] input="
        <> int.to_string(usage.input_tokens)
        <> " output="
        <> int.to_string(usage.output_tokens)
        <> " total="
        <> int.to_string(usage.total_tokens),
      )
    event.RunCompleted(output_text: output_text, usage: _) ->
      io.println("[done] " <> output_text)
    event.RunFailed(message) -> io.println("[error] " <> message)
  }
}

pub fn print_error(runtime_error: error.RuntimeError) -> Nil {
  io.println("[error] " <> error.describe(runtime_error))
}

fn mode_label(streaming: Bool) -> String {
  case streaming {
    True -> "stream"
    False -> "sync"
  }
}
