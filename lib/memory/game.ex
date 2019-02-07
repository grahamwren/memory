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
    view_state: %{showing: [], matrix: [], win: false}
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
        win: false
      }
    }}
  end

  def show(game, x, y) do
    %{view_state: %{showing: showing}} = game
    case length(showing) do
      1 -> show_new(game, x, y)
      _ -> show_new_and_hide(game, x, y)
    end
  end

  # when there is 1 card showing
  def show_new(game, x, y) do
    %{view_state: view, internal_state: internal} = game

    new_card = Matrix.fetch internal, x, y
    [{current_x, current_y} | _] = view.showing
    current_card = Matrix.fetch internal, current_x, current_y

    if (current_card == new_card) do
      # if card was correct, update view with :delete in both places
      view_matrix =
        view.matrix
        |> Matrix.update(x, y, :delete)
        |> Matrix.update(current_x, current_y, :delete)

      # deleted two cards so inc deleted_count
      deleted = game.deleted_count + 2

      if (deleted >= game.size * game.size) do
        %{game |
          deleted_count: deleted,
          view_state: %{
            view |
            showing: [],
            matrix: view_matrix,
            win: true
          }
        }
      else
        %{game |
          deleted_count: deleted,
          view_state: %{
            view |
            showing: [],
            matrix: view_matrix
          }
        }
      end
    else
      # if card was not correct, show both
      view_matrix = Matrix.update view.matrix, x, y, new_card
      %{game | view_state: %{view | showing: [{x,y} | view.showing], matrix: view_matrix}}
    end
  end

  # when there is either 0 or 2 cards showing
  def show_new_and_hide(game, x, y) do
    %{view_state: view, internal_state: internal} = game

    # hide each of the previously showing cards
    view_matrix = List.foldl view.showing, view.matrix, fn {shown_x, shown_y}, v_matrix ->
      Matrix.update v_matrix, shown_x, shown_y, :hide
    end

    # show the requested card
    new_card = Matrix.fetch internal, x, y
    view_matrix = Matrix.update view_matrix, x, y, new_card

    # return game with updated view, showing only the new card
    %{game | view_state: %{view | showing: [{x, y}], matrix: view_matrix}}
  end
end