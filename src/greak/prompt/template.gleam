import gleam/dict.{type Dict}
import gleam/result
import gleam/string

pub type TemplateError {
  MissingVariable(name: String)
  UnclosedPlaceholder(source: String)
}

pub fn render(
  source: String,
  values: Dict(String, String),
) -> Result(String, TemplateError) {
  case string.split_once(source, on: "{{") {
    Error(_) -> Ok(source)
    Ok(#(prefix, rest)) ->
      case string.split_once(rest, on: "}}") {
        Error(_) -> Error(UnclosedPlaceholder(source))
        Ok(#(raw_name, suffix)) -> {
          let name = string.trim(raw_name)
          let value_result =
            dict.get(values, name)
            |> result.map_error(fn(_) { MissingVariable(name) })

          use value <- result.try(value_result)
          use rendered_suffix <- result.try(render(suffix, values))
          Ok(prefix <> value <> rendered_suffix)
        }
      }
  }
}

pub fn describe(error: TemplateError) -> String {
  case error {
    MissingVariable(name) -> "missing template variable: " <> name
    UnclosedPlaceholder(_) -> "template contains an unclosed placeholder"
  }
}
