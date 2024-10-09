import Config

config :logger,
  handle_otp_reports: true,
  handle_sasl_reports: true

# TODO: remove when we depend on Elixir ~> 1.11.
if macro_exported?(Logger, :warning, 1) do
  config :logger, level: :warning
else
  config :logger, level: :warn
end

config :sasl, :sasl_error_logger, false
