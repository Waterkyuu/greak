import greak/agent/planner
import greak/core/usage
import greak/model/provider
import greak/tool/registry

pub fn planner_parses_numbered_steps_test() {
  let sync_invoke = fn(_) {
    Ok(provider.ProviderResponse(
      response_id: "planner_1",
      output_text: "1. Gather requirements\n2. Build provider\n3. Run tests",
      tool_calls: [],
      usage: usage.add(usage.new(), input_tokens: 4, output_tokens: 7),
    ))
  }

  let fake_provider =
    provider.new(
      conversation_mode: provider.StatelessConversation,
      invoke: sync_invoke,
      invoke_stream: fn(request, _) { sync_invoke(request) },
    )

  let config = planner.new(fake_provider, False)
  let tools = registry.from_list([])

  let assert Ok(plan) =
    planner.run(config, tools, "Create an agent runtime", fn(_) { Nil })

  assert plan.steps
    == [
      "Gather requirements",
      "Build provider",
      "Run tests",
    ]
}
