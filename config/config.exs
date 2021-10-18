import Config

config :flowmailer,
  client_id: {:system, "FLOWMAILER_CLIENT_ID"},
  account_id: {:system, "FLOWMAILER_ACCOUNT_ID"},
  client_secret: {:system, "FLOWMAILER_CLIENT_SECRET"}

import_config "#{config_env()}.exs"

if File.exists?(Path.join(__DIR__, "#{config_env()}.secret.exs")) do
  import_config "#{config_env()}.secret.exs"
end
