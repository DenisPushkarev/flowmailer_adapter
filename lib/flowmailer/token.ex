defmodule FlowMailer.Token do
  use GenServer
  alias FlowMailer.Token

  import FlowMailer.Shared

  defstruct updated_at: nil,
            access_token: nil

  defmodule AccessToken do
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
  end

  @client_id_key :flowmailer_client_id
  @account_id_key :flowmailer_account_id
  @client_secret_key :flowmailer_client_secret

  @auth_url "https://login.flowmailer.net/oauth/token"

  def get(config) do
    GenServer.call(__MODULE__, {:get_token, config})
  end

  def handle_config(config) do
    validate_params(config)
    GenServer.cast(__MODULE__, {:configure, config})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def handle_cast({:configure, %{flowmailer_client_id: client_id}}, state) do
    new_state = Map.put_new(state, client_id, %Token{})
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:get_token, config}, _from, state) do
    client_id = get_config_value(config, @client_id_key)

    result =
      case Map.get(state, client_id) do
        nil ->
          add_new_token(client_id, state, config)

        %Token{updated_at: nil} ->
          do_refresh_token(client_id, state, config)

        %Token{} ->
          maybe_refresh_token(client_id, state, config)
      end

    case result do
      {:ok, state} ->
        %Token{access_token: access_token} = Map.get(state, client_id)
        %AccessToken{access_token: token_value} = access_token
        {:reply, {:ok, token_value}, state}

      {:error, error, state} ->
        {:reply, {:error, error}, state}
    end
  end

  defp add_new_token(client_id, state, config) do
    do_refresh_token(client_id, state, config)
  end

  defp maybe_refresh_token(client_id, state, config) do
    %Token{updated_at: updated_at, access_token: access_token = %AccessToken{}} =
      Map.get(state, client_id)

    expire_ts = DateTime.add(updated_at, access_token.expires_in - 2, :second)
    expires? = DateTime.diff(expire_ts, DateTime.utc_now()) < 0

    if expires? do
      {result, state} = do_refresh_token(client_id, state, config)
      {result, state}
    else
      {:ok, state}
    end
  end

  defp do_refresh_token(client_id, state, config) do
    case fetch_token(config) do
      {:ok, token_data} ->
        new_state =
          Map.put(state, client_id, %Token{
            updated_at: DateTime.utc_now(),
            access_token: token_to_struct(token_data)
          })

        {:ok, new_state}

      {:error, error} ->
        {:error, error, state}
    end
  end

  defp token_to_struct(data) do
    %AccessToken{
      access_token: data["access_token"],
      expires_in: data["expires_in"],
      scope: data["scope"],
      token_type: data["token_type"]
    }
  end

  defp fetch_token(config) do
    client_id = get_config_value(config, @client_id_key)
    client_secret = get_config_value(config, @client_secret_key)

    body =
      URI.encode_query(%{
        "client_id" => client_id,
        "client_secret" => client_secret,
        "grant_type" => "client_credentials",
        "scope" => "api"
      })

    headers = [
      {"content-type", "application/x-www-form-urlencoded"}
    ]

    case :hackney.post(@auth_url, headers, body, hackney_opts(config)) do
      {:ok, code, _headers, response} when code < 299 ->
        body = response |> Bamboo.json_library().decode!()
        {:ok, body}

      {:ok, code, _, response} ->
        {:error, %{code: code, response: response}}

      error ->
        {:error, error}
    end
  rescue
    r ->
      {:error, "Error on fetching FlowMailer token: #{inspect(r)}"}
  end

  defp validate_param(config, param) do
    _value = get_config_value(config, param)
    config
  end

  defp validate_params(config) do
    config
    |> validate_param(@client_id_key)
    |> validate_param(@account_id_key)
    |> validate_param(@client_secret_key)
  end
end
