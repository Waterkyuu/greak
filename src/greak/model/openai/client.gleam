import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/list
import gleam/result

import greak/core/error.{type RuntimeError, ProviderError}
import greak/model/openai/config.{type Config}
import greak/model/openai/request as openai_request
import greak/model/openai/response
import greak/model/openai/stream
import greak/model/provider.{
  type Provider, type ProviderRequest, type ProviderResponse,
  StatefulConversation, new,
}

@external(erlang, "greak_openai_stream_ffi", "post_sse")
fn post_sse(
  url: String,
  headers: List(#(String, String)),
  body: String,
  on_line: fn(String) -> Nil,
) -> Result(String, String)

pub fn provider(config: Config) -> Provider {
  new(
    conversation_mode: StatefulConversation,
    invoke: fn(provider_request) { invoke(config, provider_request) },
    invoke_stream: fn(provider_request, on_text_delta) {
      invoke_stream(config, provider_request, on_text_delta)
    },
  )
}

pub fn invoke(
  config: Config,
  provider_request: ProviderRequest,
) -> Result(ProviderResponse, RuntimeError) {
  let body = build_body(config, provider_request, False)
  let assert Ok(base_request) = request.to(config.base_url)

  let http_request =
    base_request
    |> request.set_method(http.Post)
    |> request.set_body(body)
    |> add_headers(config)

  let http_response_result =
    httpc.send(http_request)
    |> result.map_error(fn(_error) { ProviderError("http request failed") })

  use http_response <- result.try(http_response_result)

  response.decode_output(http_response.body)
}

pub fn invoke_stream(
  config: Config,
  provider_request: ProviderRequest,
  on_text_delta: fn(String) -> Nil,
) -> Result(ProviderResponse, RuntimeError) {
  let body = build_body(config, provider_request, True)
  let headers = build_headers(config)

  let callback = fn(line: String) {
    case stream.parse_sse_line(line) {
      stream.DataChunk(payload_json) ->
        case response.decode_output_text_delta_event(payload_json) {
          Ok(delta) -> on_text_delta(delta)
          Error(_) -> Nil
        }
      _ -> Nil
    }
  }

  let transcript_result =
    post_sse(config.base_url, headers, body, callback)
    |> result.map_error(fn(message) { ProviderError(message) })

  use transcript <- result.try(transcript_result)

  stream.extract_completed_response(transcript)
}

fn build_body(
  config: Config,
  provider_request: ProviderRequest,
  stream_mode: Bool,
) -> String {
  openai_request.build_json(
    model: config.model,
    instructions: provider_request.instructions,
    input: provider_request.input,
    tools: provider_request.tools,
    stream: stream_mode,
    previous_response_id: provider_request.previous_response_id,
  )
}

fn add_headers(
  http_request: request.Request(String),
  config: Config,
) -> request.Request(String) {
  list.fold(
    over: build_headers(config),
    from: http_request,
    with: fn(acc, header) { request.prepend_header(acc, header.0, header.1) },
  )
}

fn build_headers(config: Config) -> List(#(String, String)) {
  [
    #("authorization", "Bearer " <> config.api_key),
    #("content-type", "application/json"),
  ]
}
