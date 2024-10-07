use Mix.Config

config :logger,
  handle_otp_reports: true,
  handle_sasl_reports: true,
  level: :warn

config :sasl, :sasl_error_logger, false
