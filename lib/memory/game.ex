defmodule Memory.Game do
  alias Memory.Game
  alias Memory.Utils
  alias Memory.Utils.Matrix

  @default_game_name "default"
  @default_game_size 4

  defstruct(
    name: @default_game_name,
    size: @default_game_size,
    deleted_count: 0,
    internal_state: [],
    view_state: %{showing: [], matrix: [], win: false, show_count: 0}
  )

  def new(name) do
    size = @default_game_size
    chars = Utils.get_chars size

    builder = &Matrix.build(size, size, &1)
    int_matrix = builder.(&Enum.at(chars, &2 * size + &1))
    view_matrix = builder.(fn _x, _y -> :hide end)

    {:ok, %Game{
      name: name,
      size: size,
      internal_state: int_matrix,
      view_state: %{
        showing: [],
        matrix: view_matrix,
        win: false,
        show_count: 0
      }
    }}
  end

  # when 0 cards showing:
  # - show card
  # - send_action :none
  def show(%{view_state: %{showing: []}} = game, x, y), do: {:none, show_card(game, x, y)}

  # when 1 card showing:
  # - if (card is already shown?): return game unchanged
  # - show card
  # - if (was match?): send_action :delete
  #   else:            send_action :hide
  def show(%{view_state: %{showing: showing}} = game, x, y) when length(showing) == 1 do
    if (hd(showing) == [x, y]) do
      {:none, game}
    else
      # show new card
      game = show_card(game, x, y)
      action = if is_showing_match(game), do: :delete, else: :hide
      win = game.deleted_count == (game.size * game.size - 2)

      {action, %Game{
        game |
        view_state: %{
          game.view_state |
          win: win
        }
      }}
    end
  end

  # when > 1 cards showing:
  # - if (was match?): delete_showing
  #   else: hide_showing
  # - show_card
  # - send_action :none
  def show(game, x, y) do
    game = if is_showing_match(game) do
      game |> delete_showing |> show_card(x, y)
    else
      game |> hide_showing |> show_card(x, y)
    end

    {:none, game}
  end

  def show_card(game, x, y) do
    %{view_state: view, internal_state: internal} = game
    if Matrix.fetch(view.matrix, x, y) == :delete do
      game
    else
      # show the requested card
      new_card = Matrix.fetch internal, x, y
      view_matrix = Matrix.update view.matrix, x, y, new_card

      # return game with card showing, show_count inc'd
      %Game{
        game |
        view_state: %{
          game.view_state |
          showing: [[x, y] | view.showing],
          matrix: view_matrix,
          show_count: view.show_count + 1
        }
      }
    end
  end

  def update_view_matrix(%{view_state: view} = game, positions, value) do
    # update at each of the given positions
    view_matrix = List.foldl positions, view.matrix, fn [shown_x, shown_y], v_matrix ->
      Matrix.update v_matrix, shown_x, shown_y, value
    end

    %Game{game | view_state: %{game.view_state | matrix: view_matrix}}
  end

  def hide_showing(%{view_state: view} = game) do
    game = update_view_matrix(game, view.showing, :hide)
    %Game{
      game |
      view_state: %{
        game.view_state |
        showing: []
      }
    }
  end

  def delete_showing(game) do
    game = update_view_matrix(game, game.view_state.showing, :delete)

    # deleted showing cards so inc deleted_count
    deleted = game.deleted_count + length(game.view_state.showing)

    %Game{game |
      deleted_count: deleted,
      view_state: %{
        game.view_state |
        showing: [],
        win: deleted >= game.size * game.size # win when deleted every card
      }
    }
  end

  def is_showing_match(%{view_state: %{showing: [[f_x, f_y], [s_x, s_y]], matrix: view_matrix}}) do
    first_card = Matrix.fetch view_matrix, f_x, f_y
    second_card = Matrix.fetch view_matrix, s_x, s_y
    first_card == second_card
  end
  def is_showing_match(_), do: false
end