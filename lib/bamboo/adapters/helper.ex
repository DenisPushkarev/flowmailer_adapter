defmodule Bamboo.FlowMailerHelper do
  def hackney_opts(config) do
    config
    |> Map.get(:hackney_opts, [])
    |> Enum.concat([:with_body])
  end

  def get_config_value(config, key, default \\ nil) do
    value =
      case Map.get(config, key, default) do
        {:system, var} -> System.get_env(var)
        {module_name, method_name, args} -> apply(module_name, method_name, args)
        fun when is_function(fun) -> fun.()
        key -> key
      end

    if value in [nil, ""] do
      raise_api_key_error(config)
    else
      value
    end
  end

  def handle_http_error(response) do
    raise "Http response error: #{inspect(response)}"
  end

  defp raise_api_key_error(config) do
    raise ArgumentError, """
    There was no API key set for the FlowMailer adapter.
    * Here are the config options that were passed in:
    #{inspect(config)}
    """
  end
end
