# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :dashboard,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :dashboard, DashboardWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: DashboardWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Dashboard.PubSub,
  live_view: [signing_salt: "G/KRX3CD"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :dashboard, Dashboard.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.

# Configure Finnhub API Key
# For development, you can set it here.
# IMPORTANT: For production, use environment variables (see runtime.exs).
# Consider moving this to config/dev.secret.exs and gitignoring it.
config :dashboard, :finnhub_api_key, "d0fm00hr01qr6dbstjpgd0fm00hr01qr6dbstjq0"

import_config "#{config_env()}.exs"
