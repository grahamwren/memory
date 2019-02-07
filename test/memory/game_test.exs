defmodule Memory.GameTest do
  use ExUnit.Case
  alias Memory.Utils.Matrix
  alias Memory.Game

  test "new game" do
    {:ok, game} = Game.new "hello"
    assert game == %Game{
      deleted_count: 0,
      name: "hello",
      size: 4,
      view_state: %{
        matrix: Matrix.build(4, 4, fn _x, _y -> :hide end),
        showing: [],
        win: false
      },
      internal_state: game.internal_state
    }
  end

  test "show cards same" do
    {:ok, game} = Game.new "default"
    internal =
      game.internal_state
      |> Matrix.update(2, 3, "A")
      |> Matrix.update(1, 1, "A")
    game = %Game{game | internal_state: internal}

    {action, game} = Game.show(game, 2, 3)

    # first shown, action is :none
    assert action == :none
    assert game.view_state.showing == [{2, 3}]
    assert game.view_state.matrix == [
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, "A",   :hide],
    ]

    {action, game} = Game.show(game, 1, 1)

    # card was the same so show both with action delete
    assert action == :delete
    assert game.view_state.showing == [{1,1}, {2,3}]
    assert game.view_state.matrix == [
      [:hide, :hide, :hide, :hide],
      [:hide, "A",   :hide, :hide],
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, "A",   :hide],
    ]
  end

  test "show cards different" do
    {:ok, game} = Game.new "default"
    internal =
      game.internal_state
      |> Matrix.update(2, 3, "A")
      |> Matrix.update(1, 1, "B")
    game = %Game{game | internal_state: internal}

    {action, game} = Game.show(game, 2, 3)

    # only one card shown so show it with action :none
    assert action == :none
    assert game.view_state.showing == [{2, 3}]
    assert game.view_state.matrix == [
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, "A",   :hide],
    ]

    {action, game} = Game.show(game, 1, 1)

    # card was different so show both with action :hide
    assert action == :hide
    assert game.view_state.showing == [{1,1}, {2,3}]
    assert game.view_state.matrix == [
      [:hide, :hide, :hide, :hide],
      [:hide, "B",   :hide, :hide],
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, "A",   :hide],
    ]
  end

  test "show cards same for win" do
    {:ok, game} = Game.new "default"
    internal =
      game.internal_state
      |> Matrix.update(2, 3, "A")
      |> Matrix.update(1, 1, "A")
    view_matrix = [
      [:delete, :delete, :delete, :delete],
      [:delete, :hide,   :delete, :delete],
      [:delete, :delete, :delete, :delete],
      [:delete, :delete, :hide,   :delete],
    ]
    deleted_count = 4 * 4 - 2
    game = %Game{
      game |
      internal_state: internal,
      deleted_count: deleted_count,
      view_state: %{
        game.view_state |
        matrix: view_matrix
      }
    }

    {action, game} = Game.show(game, 2, 3)
    assert action == :none
    assert game.view_state.showing == [{2, 3}]
    assert game.view_state.matrix == [
      [:delete, :delete, :delete, :delete],
      [:delete, :hide,   :delete, :delete],
      [:delete, :delete, :delete, :delete],
      [:delete, :delete, "A",     :delete],
    ]
    # ensure game not won yet
    assert !game.view_state.win

    {action, game} = Game.show(game, 1, 1)

    # was match so both shown, action :delete, win true
    assert action == :delete
    assert game.view_state.showing == [{1, 1}, {2, 3}]
    assert game.view_state.matrix == [
      [:delete, :delete, :delete, :delete],
      [:delete, "A",     :delete, :delete],
      [:delete, :delete, :delete, :delete],
      [:delete, :delete, "A",     :delete],
    ]
    # ensure game won
    assert game.view_state.win
  end

  test "hide showing" do
    {:ok, game} = Game.new "default"
    {_, game} = Game.show game, 1, 2
    {_, game} = Game.show game, 1, 3
    game = Game.hide_showing game
    assert game.view_state.matrix == [
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, :hide, :hide],
    ]
  end

  test "show deleted" do
    {:ok, game} = Game.new "default"
    view_matrix = Matrix.update game.view_state.matrix, 1, 1, :delete
    game = %Game{
      game |
      view_state: %{
        game.view_state |
        matrix: view_matrix
      }
    }
    {_, new_game} = Game.show game, 1, 1
    assert new_game == game
  end
end