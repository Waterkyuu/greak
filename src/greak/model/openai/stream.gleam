import gleam/list
import gleam/string

import greak/core/error.{type RuntimeError, ProviderError}
import greak/model/openai/response
import greak/model/provider.{type ProviderResponse}

pub type StreamChunk {
  EndOfStream
  DataChunk(payload_json: String)
  Ignore
}

pub fn parse_sse_line(line: String) -> StreamChunk {
  let trimmed = string.trim(line)

  case trimmed {
    "" -> Ignore
    "data: [DONE]" -> EndOfStream
    _ ->
      case string.starts_with(trimmed, "data: ") {
        True -> DataChunk(string.drop_start(trimmed, 6))
        False -> Ignore
      }
  }
}

pub fn extract_completed_response(
  transcript: String,
) -> Result(ProviderResponse, RuntimeError) {
  list.fold(
    over: string.split(transcript, on: "\n"),
    from: Error(ProviderError("missing response.completed event")),
    with: fn(acc, line) {
      case parse_sse_line(line) {
        DataChunk(payload_json) ->
          case response.decode_completed_event(payload_json) {
            Ok(provider_response) -> Ok(provider_response)
            Error(_) -> acc
          }
        _ -> acc
      }
    },
  )
}
