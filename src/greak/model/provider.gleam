import gleam/option.{type Option}

import greak/core/error.{type RuntimeError}
import greak/core/message.{type InputItem, type ToolCall}
import greak/core/usage.{type Usage}
import greak/tool/definition.{type ToolDefinition}

pub type ConversationMode {
  StatefulConversation
  StatelessConversation
}

pub type ProviderRequest {
  ProviderRequest(
    instructions: String,
    input: List(InputItem),
    tools: List(ToolDefinition),
    previous_response_id: Option(String),
  )
}

pub type ProviderResponse {
  ProviderResponse(
    response_id: String,
    output_text: String,
    tool_calls: List(ToolCall),
    usage: Usage,
  )
}

pub type Provider {
  Provider(
    conversation_mode: ConversationMode,
    invoke: fn(ProviderRequest) -> Result(ProviderResponse, RuntimeError),
    invoke_stream: fn(ProviderRequest, fn(String) -> Nil) ->
      Result(ProviderResponse, RuntimeError),
  )
}

pub fn new(
  conversation_mode conversation_mode: ConversationMode,
  invoke invoke: fn(ProviderRequest) -> Result(ProviderResponse, RuntimeError),
  invoke_stream invoke_stream: fn(ProviderRequest, fn(String) -> Nil) ->
    Result(ProviderResponse, RuntimeError),
) -> Provider {
  Provider(conversation_mode:, invoke:, invoke_stream:)
}

pub fn invoke(
  provider: Provider,
  request: ProviderRequest,
) -> Result(ProviderResponse, RuntimeError) {
  provider.invoke(request)
}

pub fn conversation_mode(provider: Provider) -> ConversationMode {
  provider.conversation_mode
}

pub fn invoke_stream(
  provider: Provider,
  request: ProviderRequest,
  on_text_delta: fn(String) -> Nil,
) -> Result(ProviderResponse, RuntimeError) {
  provider.invoke_stream(request, on_text_delta)
}
