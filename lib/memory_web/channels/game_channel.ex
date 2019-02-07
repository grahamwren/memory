defmodule MemoryWeb.GameChannel do
  use MemoryWeb, :channel

  alias Memory.Game

  def join("game:" <> name, payload, socket) do
    if authorized?(payload) do
      {:ok, game} = Game.new
      socket = socket
      |> assign(:game, game)
      |> assign(:name, name)
      {:ok, %{join: name, game: game.clientView()}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (game:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
