defmodule Bamboo.FlowMailerHelper do
  @moduledoc """
  Helper module provides FlowMailer specified functions for setting up email
  """
  import Bamboo.Email

  @doc """
  Set `flowSelector` parameter that is used by FlowMailer
  ## Example
      email
      |> set_flow("invoice)
  """
  def set_flow(%Bamboo.Email{} = email, nil) do
    email
  end

  def set_flow(%Bamboo.Email{} = email, flow) do
    put_private(email, :flowmailer_flow_selector, flow)
  end
end
