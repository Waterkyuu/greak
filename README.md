# Greak

Runtime-first agent framework for Gleam.

## Scope

This repository is building a small but reusable agent runtime inspired by the
layering of LangChain and the future orchestration direction of LangGraph.

The first milestone focuses on:

- prompt templates
- normalized runtime events
- in-process function calling
- OpenAI Responses API support
- a ReAct-style agent loop
- a CLI demo for local experiments

## Layout

- `src/greak/core/`: shared runtime types
- `src/greak/prompt/`: prompt template helpers
- `src/greak/tool/`: tool definitions and registry
- `src/greak/model/`: provider interfaces and OpenAI adapter
- `src/greak/agent/`: agent runtimes
- `src/greak/cli/`: CLI demo helpers
- `test/greak/`: focused unit tests
- `.githooks/`: repository git hooks

## Commands

```sh
gleam format
gleam test
gleam build
```

## Hooks

Run the setup script once after cloning:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup_git_hooks.ps1
```

The shared hooks enforce:

- `gleam format --check .`
- `gleam test`
- `gleam build`
- detailed commit messages with the Codex co-author trailer
