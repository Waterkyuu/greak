import gleam/list
import gleam/result
import gleam/string

import greak/agent/react
import greak/core/error.{type RuntimeError, CliError}
import greak/core/event.{type RunEvent, PlanProduced}
import greak/core/message.{type Plan, Plan}
import greak/model/provider.{type Provider}
import greak/tool/registry.{type ToolRegistry}

pub type PlannerConfig {
  PlannerConfig(react_config: react.ReactConfig, plan_prefix: String)
}

pub fn new(provider: Provider, stream: Bool) -> PlannerConfig {
  PlannerConfig(
    react_config: react.new(
      provider,
      "You are a planning agent. Produce a concise execution plan as numbered lines.",
      stream,
    ),
    plan_prefix: "",
  )
}

pub fn with_max_iterations(
  config: PlannerConfig,
  max_iterations: Int,
) -> PlannerConfig {
  PlannerConfig(
    ..config,
    react_config: react.with_max_iterations(config.react_config, max_iterations),
  )
}

pub fn with_plan_prefix(
  config: PlannerConfig,
  plan_prefix: String,
) -> PlannerConfig {
  PlannerConfig(..config, plan_prefix:)
}

pub fn run(
  config: PlannerConfig,
  tools: ToolRegistry,
  goal: String,
  emit: fn(RunEvent) -> Nil,
) -> Result(Plan, RuntimeError) {
  let planner_input = case config.plan_prefix == "" {
    True -> goal
    False -> config.plan_prefix <> "\n\nGoal: " <> goal
  }

  use result <- result.try(react.run(
    config.react_config,
    tools,
    planner_input,
    emit,
  ))

  let steps = parse_steps(result.output_text)

  case steps {
    [] -> Error(CliError("planner did not produce any steps"))
    _ -> {
      emit(PlanProduced(steps))
      Ok(Plan(steps: steps, raw_text: result.output_text))
    }
  }
}

fn parse_steps(raw_text: String) -> List(String) {
  raw_text
  |> string.split(on: "\n")
  |> list.filter_map(fn(line) {
    let trimmed = string.trim(line)
    case trimmed {
      "" -> Error(Nil)
      _ -> Ok(strip_number_prefix(trimmed))
    }
  })
}

fn strip_number_prefix(line: String) -> String {
  case string.split_once(line, on: ". ") {
    Ok(#(_, rest)) -> rest
    Error(_) ->
      case string.split_once(line, on: "- ") {
        Ok(#(_, rest)) -> rest
        Error(_) -> line
      }
  }
}
