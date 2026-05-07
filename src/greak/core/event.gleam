import greak/core/message.{type ToolCall}
import greak/core/usage.{type Usage}

pub type RunEvent {
  RunStarted
  RequestBuilt(streaming: Bool)
  ResponseStarted
  ResponseDelta(chunk: String)
  ToolCallRequested(tool_call: ToolCall)
  ToolCallCompleted(call_id: String, name: String, result_json: String)
  UsageUpdated(usage: Usage)
  RunCompleted(output_text: String, usage: Usage)
  RunFailed(message: String)
}
