import gleam/dict

import greak/prompt/template

pub fn render_template_test() {
  let values = dict.from_list([#("agent_name", "planner")])
  let assert Ok(rendered) = template.render("You are {{agent_name}}.", values)
  assert rendered == "You are planner."
}

pub fn missing_variable_test() {
  let values = dict.from_list([])
  assert template.render("Hello {{name}}", values)
    == Error(template.MissingVariable("name"))
}
