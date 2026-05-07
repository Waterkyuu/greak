import greak/core/usage

pub type Usage =
  usage.Usage

pub fn new_usage() -> Usage {
  usage.new()
}

pub fn add_usage(
  current: Usage,
  input_tokens input_tokens: Int,
  output_tokens output_tokens: Int,
) -> Usage {
  usage.add(current, input_tokens:, output_tokens:)
}
