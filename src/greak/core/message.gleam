import greak/core/usage.{type Usage}

pub type InputItem {
  UserText(text: String)
  FunctionCallRequest(call_id: String, name: String, arguments_json: String)
  FunctionCallOutput(call_id: String, output: String)
}

pub type ToolCall {
  ToolCall(call_id: String, name: String, arguments_json: String)
}

pub type AgentResult {
  AgentResult(output_text: String, usage: Usage)
}

pub type Plan {
  Plan(steps: List(String), raw_text: String)
}
