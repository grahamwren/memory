# Based on ntuck stack3.ex
# from https://khoury.neu.edu/~ntuck/courses/2019/01/cs4550/notes/09-introducing-otp/stack3.ex

defmodule Memory.GameServer do
  use GenServer
  alias Memory.Game

  # Reg & Super
  def setup do
    {:ok, _} = Registry.start_link(keys: :unique, name: __MODULE__.Registry)
    {:ok, _} = DynamicSupervisor.start_link(strategy: :one_for_one, name: __MODULE__.Super)
  end

  def reg(name) do
    {:via, Registry, {__MODULE__.Registry, name}}
  end

  # External API

  def ensure(name) do
    spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [name]},
      restart: :permanent,
      type: :worker,
    }
    case Registry.lookup(__MODULE__.Registry, name) do
      [{pid, _}] -> {:ok, pid}
      [] -> DynamicSupervisor.start_child(__MODULE__.Super, spec)
    end
  end

  def show(name, args) do
    GenServer.call(reg(name), {:show, args})
  end

  def get_view(name) do
    GenServer.call(reg(name), :get_view)
  end

  # Internal API

  def start_link(name) do
    {:ok, game} = Game.new name
    GenServer.start_link(__MODULE__, game, name: reg(name))
  end

  # Server

  def init(game) do
    {:ok, game}
  end

  def handle_call({:show, {x, y}}, _from, game) do
    {action, game} = Game.show(game, x, y)
    if action != :none, do: Process.send_after(self(), {action, game.view_state.showing}, 1_000)
    {:reply, game.view_state.matrix, game}
  end

  def handle_call(:get_view, _from, game) do
    {:reply, game.view_state.matrix, game}
  end

  # Handle Scheduled :hide and :delete

  def handle_info({:hide, positions}, %{view_state: %{showing: showing}} = game) do
    game = if positions == showing, do: Game.hide_showing(game), else: game
    {:noreply, game}
  end

  def handle_info({:delete, positions}, %{view_state: %{showing: showing}} = game) do
    game = if positions == showing, do: Game.delete_showing(game), else: game
    {:noreply, game}
  end
end