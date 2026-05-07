import gleam/dict
import gleam/io
import gleam/option.{None, Some}
import gleam/string

import greak/agent/react
import greak/cli/runtime
import greak/model/openai/client
import greak/model/openai/config
import greak/prompt/template
import greak/tool/definition
import greak/tool/registry

pub fn main() -> Nil {
  let args = runtime.arguments()

  case runtime.get_env("OPENAI_API_KEY"), args {
    None, _ -> io.println("Set OPENAI_API_KEY before running the demo.")
    _, [] -> io.println("Usage: gleam run -m greak/cli/demo -- <prompt>")
    Some(api_key), prompt_parts -> {
      let values =
        dict.from_list([
          #("agent_name", "greak-react"),
        ])

      let assert Ok(system_prompt) =
        template.render(
          "You are {{agent_name}}. Use tools when they help you answer.",
          values,
        )

      let openai = client.provider(config.new(api_key, "gpt-4.1-mini"))
      let tools =
        registry.from_list([
          echo_tool(),
          mock_weather_tool(),
        ])
      let agent = react.new(openai, system_prompt, True)
      let user_prompt = string.join(prompt_parts, with: " ")

      case react.run(agent, tools, user_prompt, runtime.print_event) {
        Ok(_) -> Nil
        Error(error) -> runtime.print_error(error)
      }
    }
  }
}

pub fn echo_tool() -> definition.ToolDefinition {
  definition.new(
    name: "echo",
    description: "Echoes the raw JSON arguments back to the model.",
    parameters_json_schema: "{\"type\":\"object\",\"properties\":{\"value\":{\"type\":\"string\"}},\"required\":[\"value\"]}",
    execute: fn(arguments_json) { Ok(arguments_json) },
  )
}

pub fn mock_weather_tool() -> definition.ToolDefinition {
  definition.new(
    name: "get_weather",
    description: "Returns a mock weather report for a requested location.",
    parameters_json_schema: "{\"type\":\"object\",\"properties\":{\"location\":{\"type\":\"string\"}},\"required\":[\"location\"]}",
    execute: fn(arguments_json) {
      Ok(
        "{\"forecast\":\"sunny\",\"source\":\"mock\",\"input\":"
        <> arguments_json
        <> "}",
      )
    },
  )
}
