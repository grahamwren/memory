defmodule MemoryWeb.PageControllerTest do
  use MemoryWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "React app loading..."
  end

  test "GET /game/default", %{conn: conn} do
    conn = get conn, "/game/default"
    assert html_response(conn, 200) =~ "React app loading..."
  end
end
