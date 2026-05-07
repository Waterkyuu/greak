import gleam/list

import greak/core/error.{type RuntimeError, ToolExecutionFailed, ToolNotFound}
import greak/tool/definition.{type ToolDefinition}

pub opaque type ToolRegistry {
  ToolRegistry(tools: List(ToolDefinition))
}

pub fn from_list(tools: List(ToolDefinition)) -> ToolRegistry {
  ToolRegistry(tools:)
}

pub fn to_list(registry: ToolRegistry) -> List(ToolDefinition) {
  let ToolRegistry(tools:) = registry
  tools
}

pub fn find(
  registry: ToolRegistry,
  name: String,
) -> Result(ToolDefinition, RuntimeError) {
  let ToolRegistry(tools:) = registry

  case list.find(tools, fn(tool) { tool.name == name }) {
    Ok(tool) -> Ok(tool)
    Error(_) -> Error(ToolNotFound(name))
  }
}

pub fn execute(
  registry: ToolRegistry,
  name: String,
  arguments_json: String,
) -> Result(String, RuntimeError) {
  case find(registry, name) {
    Ok(tool) ->
      case tool.execute(arguments_json) {
        Ok(output) -> Ok(output)
        Error(message) -> Error(ToolExecutionFailed(name, message))
      }
    Error(error) -> Error(error)
  }
}
