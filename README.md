# Greak

Greak is a Gleam agent runtime for building tool-using LLM workflows.

It currently provides:

- prompt templates
- in-process function calling
- OpenAI Responses API support
- streaming and non-streaming execution
- a ReAct-style agent loop

## Quick Start

The repository includes a local CLI demo.

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
- final usage totals

## Use Greak As a Library

The main pieces are:

- `greak/model/openai/client`: create a provider
- `greak/agent/react`: run a ReAct agent loop
- `greak/tool/definition`: define tools
- `greak/tool/registry`: register tools

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

### Run a ReAct Agent

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

  react.run(agent, tools, "Use the echo tool to repeat hello", fn(_event) {
    Nil
  })
}
```

### Observe Runtime Events

You can stream events while the agent is running:

```gleam
import gleam/io
import greak/core/event

pub fn print_event(run_event: event.RunEvent) {
  case run_event {
    event.RunStarted -> io.println("[run] started")
    event.ResponseDelta(chunk) -> io.println("[delta] " <> chunk)
    event.ToolCallRequested(tool_call) ->
      io.println("[tool] " <> tool_call.name)
    event.UsageUpdated(usage) ->
      io.println("[usage] " <> int.to_string(usage.total_tokens))
    _ -> Nil
  }
}
```

Then pass `print_event` into `react.run`.