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

    game = Game.show(game, 2, 3)
    assert game.view_state.showing == [{2, 3}]
    assert game.view_state.matrix == [
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, "A",   :hide],
    ]

    game = Game.show(game, 1, 1)

    # card was the same so show none and delete both
    assert game.view_state.showing == []
    assert game.view_state.matrix == [
      [:hide, :hide,   :hide,   :hide],
      [:hide, :delete, :hide,   :hide],
      [:hide, :hide,   :hide,   :hide],
      [:hide, :hide,   :delete, :hide],
    ]
  end

  test "show cards different" do
    {:ok, game} = Game.new "default"
    internal =
      game.internal_state
      |> Matrix.update(2, 3, "A")
      |> Matrix.update(1, 1, "B")
    game = %Game{game | internal_state: internal}

    game = Game.show(game, 2, 3)
    assert game.view_state.showing == [{2, 3}]
    assert game.view_state.matrix == [
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, :hide, :hide],
      [:hide, :hide, "A",   :hide],
    ]

    game = Game.show(game, 1, 1)

    # card was the same so show none and delete both
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

    game = Game.show(game, 2, 3)
    assert game.view_state.showing == [{2, 3}]
    assert game.view_state.matrix == [
      [:delete, :delete, :delete, :delete],
      [:delete, :hide,   :delete, :delete],
      [:delete, :delete, :delete, :delete],
      [:delete, :delete, "A",     :delete],
    ]
    # ensure game not won yet
    assert !game.view_state.win

    game = Game.show(game, 1, 1)

    # card was the same so show none and delete both
    assert game.view_state.showing == []
    assert game.view_state.matrix == [
      [:delete, :delete, :delete, :delete],
      [:delete, :delete, :delete, :delete],
      [:delete, :delete, :delete, :delete],
      [:delete, :delete, :delete, :delete],
    ]
    # ensure game won
    assert game.view_state.win
  end
end