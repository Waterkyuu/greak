import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

import greak/core/message.{type InputItem, FunctionCallOutput, UserText}
import greak/tool/definition.{type ToolDefinition}

pub fn build_json(
  model model: String,
  instructions instructions: String,
  input input: List(InputItem),
  tools tools: List(ToolDefinition),
  stream stream: Bool,
  previous_response_id previous_response_id: Option(String),
) -> String {
  let fields = [
    #("model", quote(model)),
    #("instructions", quote(instructions)),
    #("input", encode_input_items(input)),
    #("tools", encode_tools(tools)),
    #("stream", encode_bool(stream)),
  ]

  let fields = case previous_response_id {
    Some(response_id) -> [
      #("previous_response_id", quote(response_id)),
      ..fields
    ]
    None -> fields
  }

  encode_object(list.reverse(fields))
}

fn encode_input_items(items: List(InputItem)) -> String {
  let encoded_items = list.map(items, encode_input_item)
  wrap_array(encoded_items)
}

fn encode_input_item(item: InputItem) -> String {
  case item {
    UserText(text) ->
      encode_object([
        #("role", quote("user")),
        #(
          "content",
          wrap_array([
            encode_object([
              #("type", quote("input_text")),
              #("text", quote(text)),
            ]),
          ]),
        ),
      ])
    FunctionCallOutput(call_id, output) ->
      encode_object([
        #("type", quote("function_call_output")),
        #("call_id", quote(call_id)),
        #("output", quote(output)),
      ])
  }
}

fn encode_tools(tools: List(ToolDefinition)) -> String {
  let encoded_tools = list.map(tools, encode_tool)
  wrap_array(encoded_tools)
}

fn encode_tool(tool: ToolDefinition) -> String {
  encode_object([
    #("type", quote("function")),
    #("name", quote(tool.name)),
    #("description", quote(tool.description)),
    #("parameters", tool.parameters_json_schema),
  ])
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
