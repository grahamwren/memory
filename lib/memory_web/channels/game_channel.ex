defmodule MemoryWeb.GameChannel do
  use MemoryWeb, :channel
  alias Memory.GameServer

  def join("game:" <> name, payload, socket) do
    if authorized?(payload) do
      {:ok, _} = GameServer.ensure name
      socket = assign(socket, :name, name)
      {:ok, %{"join" => name, "view" => GameServer.get_view(name)}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("show", %{"x" => x, "y" => y}, socket) do
    view = GameServer.show socket.assigns[:name], {x, y}
    {:reply, {:ok, %{"view" => view}}, socket}
  end

  def handle_in("reset", _, socket) do
    view = GameServer.reset socket.assigns[:name]
    {:reply, {:ok, %{"view" => view}}, socket}
  end

  def handle_in("get_view", _, socket) do
    {:reply, {:ok, %{view: GameServer.get_view(socket.assigns[:name])}}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
