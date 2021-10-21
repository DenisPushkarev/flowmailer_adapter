# FlowmailerAdapter

A [FlowMailer](https://flowmailer.com/) Adapter for the [Bamboo](https://github.com/thoughtbot/bamboo) email app.

## Installation

1. Add dependency in your `mix.exs`:

```elixir
def deps do
  [
    {:flowmailer_adapter, "~> 0.1.0"}
  ]
end
```

2. Ensure bamboo is started before your application:

```elixir
def application do
  [applications: [:bamboo]]
end
```

3. Add FlowMailer config into your config:

```elixir
config :my_app, MyApp.Mailer, adapter: Bamboo.FlowMailerAdapter
  flowmailer_client_id: "your-client-id",
  flowmailer_account_id: "your-account-id",
  flowmailer_client_secret: "your-client-secret"
  # flowmailer_client_secret: {:system, "FLOWMAILER_CLIENT_SECRET"} format as value also feasible

```

4. Follow Bamboo [Getting Started Guide](https://github.com/thoughtbot/bamboo#getting-started)

5. Optionally add `hackney_options`

```elixir
# In your config/config.exs file
config :my_app, MyApp.Mailer,
  adapter: Bamboo.FlowMailerAdapter,
  hackney_options: [
    connect_timeout: 8_000,
    recv_timeout: 5_000
  ]
```

## Using templates

The FlowMailer adapter provides a helper module for setting the flow of an
email.

```elixir
defmodule MyApp.Mail do
  import Bamboo.FlowMailerHelper

  def some_email do
    email
    |> set_flow("invoice")
  end
end
```

### Example

```elixir
defmodule MyApp.Mail do
  import Bamboo.FlowMailerHelper

  def send(email) do
    email
    |> from("test@test.com")
    |> set_flow("paymnet")
  end
end
```

Documentation published on [https://hexdocs.pm/flowmailer_adapter](https://hexdocs.pm/flowmailer_adapter).
