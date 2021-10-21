defmodule Bamboo.FlowMailerAdapter do
  @moduledoc """
  Sends email using FlowMailer API.
  Use this adapter to send emails through FlowMailer API.
  """
  alias Bamboo.Email
  alias FlowMailer.Token
  import Bamboo.ApiError
  import FlowMailer.Shared

  @behaviour Bamboo.Adapter

  @default_flowmailer_host "https://api.flowmailer.net"
  @service_name "FlowMailer"

  @doc false
  def supports_attachments?, do: true

  @doc false
  def handle_config(config) do
    Token.handle_config(config)
    config
  end

  defp send_path(config) do
    account_id = get_config_value(config, :flowmailer_account_id)
    "#{account_id}/messages/submit"
  end

  def default_flowmailer_host(config) do
    get_config_value(config, :flowmailer_host, @default_flowmailer_host)
  end

  def deliver(email, config) do
    body = email |> to_flowmailer_body(config) |> Bamboo.json_library().encode!()
    url = default_flowmailer_host(config) |> URI.merge(send_path(config)) |> to_string()
    token = get_token!(config)

    case :hackney.post(
           url,
           headers_with_token(token),
           body,
           hackney_opts(config)
         ) do
      {:ok, status, _headers, response} when status > 299 ->
        filtered_params = body |> Bamboo.json_library().decode!()
        {:error, build_api_error(@service_name, response, filtered_params)}

      {:ok, status, headers, response} ->
        {:ok, %{status_code: status, headers: headers, body: response}}

      {:error, reason} ->
        {:error, build_api_error(inspect(reason))}
    end
  catch
    :throw, {:error, _} = error -> error
  end

  defp get_token!(config) do
    case Token.get(config) do
      {:ok, token} -> token
      {:error, reason} -> raise "Token error: #{inspect(reason)}"
    end
  end

  defp headers_with_token(token) do
    [
      {"Authorization", "Bearer #{token}"},
      {"Accept", "Application/json; Charset=utf-8"},
      {"Content-Type", "application/json"}
    ]
  end

  defp to_flowmailer_body(%Email{} = email, _config) do
    base_message()
    |> put_attachments(email)
    |> put_flow_selector(email)
    |> put_data(email)
    |> put_header_from_address(email)
    |> put_header_from_name(email)
    |> put_header_to_address(email)
    |> put_header_to_name(email)
    |> put_headers(email)
    |> put_html(email)
    |> put_mime(email)
    |> put_recipient_address(email)
    |> put_schedule_at(email)
    |> put_sender_address(email)
    |> put_subject(email)
    |> put_tags(email)
    |> put_text(email)
  end

  defp base_message() do
    %{messageType: "EMAIL"}
  end

  defp put_attachments(message, %Email{attachments: attachments}) do
    transformed =
      attachments
      |> Enum.reverse()
      |> Enum.map(fn attachment ->
        %{
          content: Base.encode64(attachment.data),
          contentId: attachment.content_id,
          disposition: "attachment",
          contentType: attachment.content_type,
          filename: attachment.filename
        }
      end)

    Map.put(message, :attachments, transformed)
  end

  defp put_data(message, %Email{assigns: nil}), do: message

  defp put_data(message, %Email{assigns: assigns}) do
    Map.put(message, "data", assigns)
  end

  defp put_flow_selector(message, %Email{private: %{flowmailer_flow_selector: flow_selector}}) do
    Map.put(message, "flowSelector", flow_selector)
  end

  defp put_flow_selector(message, _), do: message

  defp put_header_from_address(message, %Email{headers: %{"From" => from}}) do
    Map.put(message, "headerFromAddress", from)
  end

  defp put_header_from_address(message, %Email{headers: %{"from" => from}}) do
    Map.put(message, "headerFromAddress", from)
  end

  defp put_header_from_address(message, %Email{}), do: message

  defp put_header_from_name(message, _), do: message

  defp put_header_to_address(message, %Email{headers: %{"To" => to}}) do
    Map.put(message, "headerToAddress", to)
  end

  defp put_header_to_address(message, %Email{headers: %{"to" => to}}) do
    Map.put(message, "headerToAddress", to)
  end

  defp put_header_to_address(message, _), do: message

  defp put_header_to_name(message, _), do: message

  defp put_headers(message, %Email{headers: headers}) when is_map(headers) do
    headers_without_tuple_values =
      headers
      |> Map.delete("To")
      |> Map.delete("to")
      |> Map.delete("from")
      |> Map.delete("From")

    Map.put(message, "headers", headers_without_tuple_values)
  end

  defp put_headers(message, _), do: message

  defp put_html(message, %Email{html_body: nil}), do: message

  defp put_html(message, %Email{html_body: html}) do
    Map.put(message, "html", html)
  end

  defp put_mime(message, _), do: message

  defp to_address({_, address}), do: address
  defp to_address([{_, address} | _]), do: address
  defp to_address(nil), do: nil

  defp put_recipient_address(message, %Email{to: to}) do
    Map.put(message, "recipientAddress", to_address(to))
  end

  defp put_schedule_at(message, %Email{private: %{flowmailer_schedule_at: nil}}), do: message

  defp put_schedule_at(message, %Email{private: %{flowmailer_schedule_at: schedule_at}}) do
    Map.put(message, "scheduleAt", schedule_at)
  end

  defp put_schedule_at(message, _), do: message

  defp put_sender_address(message, %Email{from: from}) do
    Map.put(message, "senderAddress", to_address(from))
  end

  defp put_subject(message, %Email{subject: nil}), do: message

  defp put_subject(message, %Email{subject: subject}) do
    Map.put(message, "subject", subject)
  end

  defp put_tags(message, %Email{private: %{flowmailer: %{tags: tags}}}) when is_list(tags) do
    Map.put(message, "tags", tags)
  end

  defp put_tags(message, _), do: message

  defp put_text(message, %Email{text_body: nil}), do: message

  defp put_text(message, %Email{text_body: text}) do
    Map.put(message, "text", text)
  end
end
