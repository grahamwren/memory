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

  def register_state_listener(name, pid), do: GenServer.cast(reg(name), {:register, pid})
  def show(name, args), do: GenServer.call(reg(name), {:show, args})
  def reset(name), do: GenServer.call(reg(name), :reset)
  def get_view(name), do: GenServer.call(reg(name), :get_view)

  # Internal API

  def start_link(name) do
    {:ok, game} = Game.new name
    state = %{game: game, listeners: []}
    GenServer.start_link(__MODULE__, state, name: reg(name))
  end

  # Server

  def init(state), do: {:ok, state}

  def handle_call({:show, {x, y}}, _from, %{listeners: listeners, game: game} = state) do
    {action, game} = Game.show(game, x, y)
    if action == :handle, do: Process.send_after(self(), {:handle, game.view_state.showing}, 1_000)
    listeners = notify_listeners listeners, game.view_state
    {:reply, game.view_state, %{state | listeners: listeners, game: game}}
  end

  def handle_call(:get_view, _from, state) do
    {:reply, state.game.view_state, state}
  end

  def handle_call(:reset, _from, state) do
    {:ok, game} = Game.new state.game.name
    {:reply, game.view_state, %{state | game: game}}
  end

  def handle_cast({:register, pid}, state) do
    {:noreply, %{state | listeners: [pid | state.listeners]}}
  end

  # Handle Scheduled

  def handle_info({:handle, positions}, %{
    listeners: listeners,
    game: %{view_state: %{showing: showing}} = game
  } = state) do
    game = if positions == showing, do: Game.handle_showing(game), else: game
    listeners = notify_listeners listeners, game.view_state
    {:noreply, %{state | listeners: listeners, game: game}}
  end

  # Helpers

  def notify_listeners([pid | rest], view_state) do
    if Process.alive?(pid) do
      send pid, {:new_state, view_state}
      [pid | notify_listeners(rest, view_state)]
    else
      notify_listeners rest, view_state
    end
  end
  def notify_listeners([], _), do: []
end