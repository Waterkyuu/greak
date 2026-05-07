import gleam/json
import gleam/list
import gleam/string

import greak/core/message.{
  type InputItem, FunctionCallOutput, FunctionCallRequest, UserText,
}
import greak/tool/definition.{type ToolDefinition}

pub fn build_json(
  model model: String,
  instructions instructions: String,
  input input: List(InputItem),
  tools tools: List(ToolDefinition),
  stream stream: Bool,
) -> String {
  encode_object([
    #("model", quote(model)),
    #("messages", encode_messages(instructions, input)),
    #("tools", encode_tools(tools)),
    #("stream", encode_bool(stream)),
  ])
}

fn encode_messages(instructions: String, input: List(InputItem)) -> String {
  let messages = [
    encode_object([
      #("role", quote("system")),
      #("content", quote(instructions)),
    ]),
    ..list.map(input, encode_input_item)
  ]

  wrap_array(messages)
}

fn encode_input_item(item: InputItem) -> String {
  case item {
    UserText(text) ->
      encode_object([
        #("role", quote("user")),
        #("content", quote(text)),
      ])
    FunctionCallRequest(call_id, name, arguments_json) ->
      encode_object([
        #("role", quote("assistant")),
        #("content", quote("")),
        #(
          "tool_calls",
          wrap_array([
            encode_object([
              #("id", quote(call_id)),
              #("type", quote("function")),
              #(
                "function",
                encode_object([
                  #("name", quote(name)),
                  #("arguments", quote(arguments_json)),
                ]),
              ),
            ]),
          ]),
        ),
      ])
    FunctionCallOutput(call_id, output) ->
      encode_object([
        #("role", quote("tool")),
        #("tool_call_id", quote(call_id)),
        #("content", quote(output)),
      ])
  }
}

fn encode_tools(tools: List(ToolDefinition)) -> String {
  let encoded_tools =
    list.map(tools, fn(tool) {
      encode_object([
        #("type", quote("function")),
        #(
          "function",
          encode_object([
            #("name", quote(tool.name)),
            #("description", quote(tool.description)),
            #("parameters", tool.parameters_json_schema),
          ]),
        ),
      ])
    })

  wrap_array(encoded_tools)
}

fn encode_object(fields: List(#(String, String))) -> String {
  fields
  |> list.map(fn(field) { quote(field.0) <> ":" <> field.1 })
  |> string.join(with: ",")
  |> fn(content) { "{" <> content <> "}" }
}

fn wrap_array(values: List(String)) -> String {
  "[" <> string.join(values, with: ",") <> "]"
}

fn quote(value: String) -> String {
  json.string(value)
  |> json.to_string
}

fn encode_bool(value: Bool) -> String {
  case value {
    True -> "true"
    False -> "false"
  }
}
