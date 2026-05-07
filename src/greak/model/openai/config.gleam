pub type Config {
  Config(api_key: String, model: String, base_url: String, timeout_ms: Int)
}

pub fn new(api_key: String, model: String) -> Config {
  Config(
    api_key: api_key,
    model: model,
    base_url: "https://api.openai.com/v1/responses",
    timeout_ms: 30_000,
  )
}

pub fn with_timeout(config: Config, timeout_ms: Int) -> Config {
  Config(..config, timeout_ms:)
}

pub fn with_base_url(config: Config, base_url: String) -> Config {
  Config(..config, base_url:)
}
