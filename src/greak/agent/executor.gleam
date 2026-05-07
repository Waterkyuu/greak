import gleam/list
import gleam/result

import greak/agent/react
import greak/core/error.{type RuntimeError}
import greak/core/event.{type RunEvent}
import greak/core/message.{type AgentResult, type Plan, AgentResult, Plan}
import greak/core/usage as runtime_usage
import greak/model/provider.{type Provider}
import greak/tool/registry.{type ToolRegistry}

pub type ExecutorConfig {
  ExecutorConfig(react_config: react.ReactConfig, step_prefix: String)
}

pub fn new(provider: Provider, stream: Bool) -> ExecutorConfig {
  ExecutorConfig(
    react_config: react.new(
      provider,
      "You are an execution agent. Complete the requested step and return a concise result.",
      stream,
    ),
    step_prefix: "",
  )
}

pub fn with_max_iterations(
  config: ExecutorConfig,
  max_iterations: Int,
) -> ExecutorConfig {
  ExecutorConfig(
    ..config,
    react_config: react.with_max_iterations(config.react_config, max_iterations),
  )
}

pub fn with_step_prefix(
  config: ExecutorConfig,
  step_prefix: String,
) -> ExecutorConfig {
  ExecutorConfig(..config, step_prefix:)
}

pub fn run_plan(
  config: ExecutorConfig,
  tools: ToolRegistry,
  plan: Plan,
  emit: fn(RunEvent) -> Nil,
) -> Result(AgentResult, RuntimeError) {
  let Plan(steps:, ..) = plan

  let seed = AgentResult(output_text: "", usage: runtime_usage.new())

  list.fold(over: steps, from: Ok(seed), with: fn(acc, step) {
    use previous <- result.try(acc)

    let prompt = case previous.output_text == "" {
      True -> build_step_prompt(config, step, "")
      False -> build_step_prompt(config, step, previous.output_text)
    }

    use step_result <- result.try(react.run(
      config.react_config,
      tools,
      prompt,
      emit,
    ))

    Ok(AgentResult(
      output_text: append_result(
        previous.output_text,
        step,
        step_result.output_text,
      ),
      usage: runtime_usage.merge(previous.usage, step_result.usage),
    ))
  })
}

fn build_step_prompt(
  config: ExecutorConfig,
  step: String,
  completed_context: String,
) -> String {
  let base = case completed_context == "" {
    True -> "Execute this step:\n" <> step
    False ->
      "Completed context:\n"
      <> completed_context
      <> "\n\nExecute this next step:\n"
      <> step
  }

  case config.step_prefix == "" {
    True -> base
    False -> config.step_prefix <> "\n\n" <> base
  }
}

fn append_result(current: String, step: String, result_text: String) -> String {
  let section = "Step: " <> step <> "\nResult: " <> result_text

  case current == "" {
    True -> section
    False -> current <> "\n\n" <> section
  }
}
