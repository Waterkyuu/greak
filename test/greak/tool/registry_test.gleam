import greak/tool/definition
import greak/tool/registry

pub fn registry_finds_tool_test() {
  let tool =
    definition.new(
      name: "echo",
      description: "Returns the same payload",
      parameters_json_schema: "{\"type\":\"object\"}",
      execute: fn(arguments_json) { Ok(arguments_json) },
    )

  let tools = registry.from_list([tool])
  let assert Ok(found) = registry.find(tools, "echo")
  assert found.name == "echo"
}
