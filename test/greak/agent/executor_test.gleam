import greak/agent/executor
import greak/core/message.{Plan}
import greak/core/usage
import greak/model/provider
import greak/tool/registry

pub fn executor_runs_each_plan_step_test() {
  let sync_invoke = fn(request: provider.ProviderRequest) {
    Ok(provider.ProviderResponse(
      response_id: "exec_1",
      output_text: "done: " <> request.instructions,
      tool_calls: [],
      usage: usage.add(usage.new(), input_tokens: 2, output_tokens: 3),
    ))
  }

  let fake_provider =
    provider.new(
      conversation_mode: provider.StatelessConversation,
      invoke: sync_invoke,
      invoke_stream: fn(request, _) { sync_invoke(request) },
    )

  let config = executor.new(fake_provider, False)
  let tools = registry.from_list([])
  let plan = Plan(steps: ["First step", "Second step"], raw_text: "")

  let assert Ok(result) = executor.run_plan(config, tools, plan, fn(_) { Nil })

  assert result.output_text != ""
  assert result.usage.total_tokens == 10
}
