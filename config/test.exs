import Config

config :logger,
  level: :warning,
  handle_otp_reports: true,
  handle_sasl_reports: true

config :sasl, :sasl_error_logger, false
