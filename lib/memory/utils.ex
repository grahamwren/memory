defmodule Memory.Utils do
  def get_chars(size) do
    count = (size * size) / 2
    chars = Enum.map ?A..trunc(?A + count - 1), fn n -> <<n>> end
    chars = chars ++ chars
    Enum.shuffle chars
  end

  defmodule Matrix do
    def build(width, height, fun \\ fn x, y -> {x,y} end) do
      # turns out ranges are inclusive which is kinda dumb, why no .. and ... like ruby?
      Enum.map 0..height - 1, fn y ->
        Enum.map 0..width - 1, fn x ->
          fun.(x, y)
        end
      end
    end

    def update(matrix, x, y, value) do
      row = Enum.at(matrix, y)
      row = List.replace_at row, x, value
      List.replace_at matrix, y, row
    end

    def fetch(matrix, x, y) do
      Enum.at Enum.at(matrix, y), x
    end
  end
end