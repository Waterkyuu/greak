pub type ToolDefinition {
  ToolDefinition(
    name: String,
    description: String,
    parameters_json_schema: String,
    execute: fn(String) -> Result(String, String),
  )
}

pub fn new(
  name name: String,
  description description: String,
  parameters_json_schema parameters_json_schema: String,
  execute execute: fn(String) -> Result(String, String),
) -> ToolDefinition {
  ToolDefinition(name:, description:, parameters_json_schema:, execute:)
}

pub fn run(
  tool: ToolDefinition,
  arguments_json: String,
) -> Result(String, String) {
  tool.execute(arguments_json)
}
