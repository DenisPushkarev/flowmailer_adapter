defmodule FlowMailer.Token do
  use GenServer
  alias FlowMailer.Token
  alias Bamboo.FlowMailerHelper
  alias Bamboo.AdapterHelper

  @type t :: %__MODULE__{
          access_token: String.t(),
          token_type: String.t(),
          expires_in: non_neg_integer,
          scope: String.t()
        }
  defstruct [
    :access_token,
    :token_type,
    :expires_in,
    :scope
  ]

  @auth_url "https://login.flowmailer.net/oauth/token"

  def get() do
    GenServer.call(__MODULE__, :get_token)
  end

  def fetch_token() do
    body =
      URI.encode_query(%{
        "client_id" => Application.fetch_env!(:flowmailer, :client_id),
        "client_secret" => Application.fetch_env!(:flowmailer, :client_secret),
        "grant_type" => "client_credentials",
        "scope" => "api"
      })

    headers = [
      {"content-type", "application/x-www-form-urlencoded"}
    ]

    case :hackney.post(@auth_url, headers, body, [:with_body]) do
      {:ok, code, _headers, response} when code < 299 ->
        body = response |> Bamboo.json_library().decode!()
        {:ok, body}

      error ->
        FlowMailerHelper.handle_http_error(error)
    end
  end

  @impl true
  def init(_opts) do
    {:ok,
     %{
       token: %Token{},
       updated_at: nil
     }}
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def handle_call(:get_token, _from, %{updated_at: nil} = state) do
    {result, new_state} = refresh_token(state)
    {:reply, result, new_state}
  end

  @impl true
  def handle_call(:get_token, _from, %{token: %Token{expires_in: nil}} = state) do
    {result, new_state} = refresh_token(state)
    {:reply, result, new_state}
  end

  @impl true
  def handle_call(:get_token, _from, state) do
    expire_ts = DateTime.add(state.updated_at, state.token.expires_in - 10, :second)
    expires? = DateTime.diff(expire_ts, DateTime.utc_now()) < 0

    if expires? do
      {result, new_state} = refresh_token(state)
      {:reply, result, new_state}
    else
      {:reply, {:ok, state.token}, state}
    end
  end

  defp refresh_token(state) do
    case fetch_token() do
      {:ok, token_data} ->
        new_state = %{
          state
          | updated_at: DateTime.utc_now(),
            token: token_to_struct(token_data)
        }

        {{:ok, new_state.token}, new_state}

      error ->
        {error, state}
    end
  end

  defp token_to_struct(data) do
    %Token{
      access_token: data["access_token"],
      expires_in: data["expires_in"],
      scope: data["scope"],
      token_type: data["token_type"]
    }
  end
end
