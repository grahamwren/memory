defmodule MemoryWeb.GameChannel do
  use MemoryWeb, :channel
  alias Memory.GameServer

  def join("game:" <> name, payload, socket) do
    if authorized?(payload) do
      {:ok, _} = GameServer.ensure name
      socket = assign(socket, :name, name)
      {:ok, %{join: name, view: GameServer.get_view(name)}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("show", %{"x" => x, "y" => y}, socket) do
    view = GameServer.show socket.assigns[:name], {x, y}
    broadcast! socket, "ok", %{view: view}
    {:noreply, socket}
  end

  def handle_in("reset", _, socket) do
    view = GameServer.reset socket.assigns[:name]
    broadcast! socket, "ok", %{view: view}
    {:noreply, socket}
  end

  def handle_in("get_view", _, socket) do
    name = socket.assigns[:name]
    # spawn listener
    spawn fn -> listen_for_game_state name, socket end
    {:reply, {:ok, %{view: GameServer.get_view(name)}}, socket}
  end

  def listen_for_game_state(name, socket) do
    GameServer.register_state_listener name, self()
    state_fetch_loop socket
  end

  def state_fetch_loop(socket) do
    receive do
      {:new_state, view_state} ->
        broadcast! socket, "ok", %{view: view_state}
    end
    state_fetch_loop socket
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
