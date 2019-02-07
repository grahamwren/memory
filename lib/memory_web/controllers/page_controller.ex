defmodule MemoryWeb.PageController do
  use MemoryWeb, :controller

  def index(conn, _params) do
    render conn, "index.html", name: ""
  end

  def game(conn, %{"name" => name}) do
    render conn, "index.html", name: name
  end
end
