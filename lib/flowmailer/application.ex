defmodule FlowMailer.Application do
  @moduledoc false
  use Application
  alias FlowMailer.Token
  @impl true
  def start(_type, _args) do
    children = [
      {Token, name: Token}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
