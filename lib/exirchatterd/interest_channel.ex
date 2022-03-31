defmodule Exirchatterd.InterestChannel do
  @moduledoc """
  Interests are mapped to "#" IRC Channels with their Handle128s.
  """
  require Logger
  use GenServer

  @impl true
  def init(name: name, max: max) do
    {:ok, %{name: name, max: max, users: []}}
  end

  # SEE: RFC2812 3.2.1
  @impl true
  def handle_cast({:join, user_pid}, %{name: name, max: max, users: users}) do
  end

  # SEE: RFC2812 3.2.2
  @impl true
  def handle_cast({:part, user_pid}, %{name: name, max: max, users: users}) do
  end

  # SEE: RFC2812 3.2.3
  @impl true
  def handle_cast({:channel_mode, user_pid}, %{name: name, max: max, users: users}) do
  end

  # SEE: RFC2812 3.2.4
  @impl true
  def handle_cast({:topic, user_pid}, %{name: name, max: max, users: users}) do
  end

  # SEE: RFC2812 3.2.1
  @impl true
  def handle_cast({:names, user_pid}, %{name: name, max: max, users: users}) do
  end
end
