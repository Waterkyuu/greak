import gleam/option.{type Option, None, Some}

pub type Config {
  Config(
    api_key: String,
    model: String,
    base_url: String,
    timeout_ms: Int,
    app_url: Option(String),
    app_name: Option(String),
  )
}

pub fn new(api_key: String, model: String) -> Config {
  Config(
    api_key: api_key,
    model: model,
    base_url: "https://openrouter.ai/api/v1/chat/completions",
    timeout_ms: 30_000,
    app_url: None,
    app_name: None,
  )
}

pub fn with_timeout(config: Config, timeout_ms: Int) -> Config {
  Config(..config, timeout_ms:)
}

pub fn with_base_url(config: Config, base_url: String) -> Config {
  Config(..config, base_url:)
}

pub fn with_app_url(config: Config, app_url: String) -> Config {
  Config(..config, app_url: Some(app_url))
}

pub fn with_app_name(config: Config, app_name: String) -> Config {
  Config(..config, app_name: Some(app_name))
}
