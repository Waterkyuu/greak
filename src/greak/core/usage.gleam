pub type Usage {
  Usage(input_tokens: Int, output_tokens: Int, total_tokens: Int)
}

pub fn new() -> Usage {
  Usage(input_tokens: 0, output_tokens: 0, total_tokens: 0)
}

pub fn add(
  current: Usage,
  input_tokens input_tokens: Int,
  output_tokens output_tokens: Int,
) -> Usage {
  Usage(
    input_tokens: current.input_tokens + input_tokens,
    output_tokens: current.output_tokens + output_tokens,
    total_tokens: current.total_tokens + input_tokens + output_tokens,
  )
}

pub fn merge(left: Usage, right: Usage) -> Usage {
  Usage(
    input_tokens: left.input_tokens + right.input_tokens,
    output_tokens: left.output_tokens + right.output_tokens,
    total_tokens: left.total_tokens + right.total_tokens,
  )
}
