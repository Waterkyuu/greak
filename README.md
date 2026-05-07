# Greak

Greak is a Gleam agent runtime for building tool-using LLM workflows.

It currently provides:

- prompt templates
- in-process function calling
- OpenAI Responses API support
- OpenRouter chat-completions support
- streaming and non-streaming execution
- a ReAct-style agent loop
- planner and executor agent modes

## Quick Start

The repository includes a local CLI demo for the OpenAI provider.

Set your API key:

```powershell
$env:OPENAI_API_KEY="your-api-key"
```

Run the demo:

```sh
gleam run -m greak/cli/demo -- "What is the weather in Shanghai?"
```

The demo prints intermediate runtime events such as:

- response deltas
- requested tool calls
- tool call results
- generated plans
- final usage totals

### Define a Tool

```gleam
import greak/tool/definition

pub fn echo_tool() {
  definition.new(
    name: "echo",
    description: "Echoes the raw JSON arguments back to the model.",
    parameters_json_schema: "{\"type\":\"object\",\"properties\":{\"value\":{\"type\":\"string\"}},\"required\":[\"value\"]}",
    execute: fn(arguments_json) { Ok(arguments_json) },
  )
}
```

### Run a ReAct Agent with OpenAI

```gleam
import greak/agent/react
import greak/model/openai/client
import greak/model/openai/config
import greak/tool/registry

pub fn run_agent(api_key: String) {
  let provider =
    config.new(api_key, "gpt-4.1-mini")
    |> client.provider

  let tools =
    registry.from_list([
      echo_tool(),
    ])

  let agent =
    react.new(
      provider,
      "You are a helpful assistant. Use tools when they help.",
      True,
    )
    |> react.with_max_iterations(30)

  react.run(agent, tools, "Use the echo tool to repeat hello", fn(_event) {
    Nil
  })
}
```

### Run a ReAct Agent with OpenRouter

```gleam
import greak/agent/react
import greak/model/openrouter/client
import greak/model/openrouter/config
import greak/tool/registry

pub fn run_agent(api_key: String) {
  let provider =
    config.new(api_key, "openai/gpt-4.1-mini")
    |> config.with_app_name("greak-demo")
    |> client.provider

  let tools =
    registry.from_list([
      echo_tool(),
    ])

  let agent =
    react.new(
      provider,
      "You are a helpful assistant. Use tools when they help.",
      True,
    )

  react.run(agent, tools, "Use the echo tool to repeat hello", fn(_event) {
    Nil
  })
}
```

### Generate a Plan

```gleam
import greak/agent/planner
import greak/model/openrouter/client
import greak/model/openrouter/config
import greak/tool/registry

pub fn make_plan(api_key: String) {
  let provider =
    config.new(api_key, "openai/gpt-4.1-mini")
    |> client.provider

  let planner =
    planner.new(provider, False)
    |> planner.with_max_iterations(10)

  planner.run(
    planner,
    registry.from_list([]),
    "Design and implement a weather assistant",
    fn(_event) { Nil },
  )
}
```

### Execute a Plan

```gleam
import greak/agent/executor
import greak/core/message.{Plan}
import greak/model/openrouter/client
import greak/model/openrouter/config
import greak/tool/registry

pub fn execute_plan(api_key: String) {
  let provider =
    config.new(api_key, "openai/gpt-4.1-mini")
    |> client.provider

  let executor =
    executor.new(provider, False)
    |> executor.with_max_iterations(10)

  let plan =
    Plan(
      steps: ["Gather requirements", "Implement the provider", "Run tests"],
      raw_text: "",
    )

  executor.run_plan(
    executor,
    registry.from_list([]),
    plan,
    fn(_event) { Nil },
  )
}
```

### Observe Runtime Events

You can stream events while the agent is running:

```gleam
import gleam/int
import gleam/io
import greak/core/event

pub fn print_event(run_event: event.RunEvent) {
  case run_event {
    event.RunStarted -> io.println("[run] started")
    event.ResponseDelta(chunk) -> io.println("[delta] " <> chunk)
    event.ToolCallRequested(tool_call) ->
      io.println("[tool] " <> tool_call.name)
    event.PlanProduced(steps) ->
      io.println("[plan] " <> int.to_string(list.length(steps)) <> " steps")
    event.UsageUpdated(usage) ->
      io.println("[usage] " <> int.to_string(usage.total_tokens))
    _ -> Nil
  }
}
```

Then pass `print_event` into `react.run`, `planner.run`, or
`executor.run_plan`.
