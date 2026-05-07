import gleam/int

pub type RuntimeError {
  TemplateError(message: String)
  ProviderError(message: String)
  ResponseDecodeFailed(message: String)
  ToolNotFound(name: String)
  ToolExecutionFailed(name: String, message: String)
  MaxIterationsExceeded(limit: Int)
  CliError(message: String)
}

pub fn describe(error: RuntimeError) -> String {
  case error {
    TemplateError(message) -> "template error: " <> message
    ProviderError(message) -> "provider error: " <> message
    ResponseDecodeFailed(message) -> "response decode failed: " <> message
    ToolNotFound(name) -> "tool not found: " <> name
    ToolExecutionFailed(name, message) ->
      "tool execution failed for " <> name <> ": " <> message
    MaxIterationsExceeded(limit) ->
      "react agent exceeded the maximum iteration limit of "
      <> int.to_string(limit)
    CliError(message) -> "cli error: " <> message
  }
}
