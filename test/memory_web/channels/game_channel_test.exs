defmodule MemoryWeb.GameChannelTest do
  use MemoryWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      socket(MemoryWeb.UserSocket, "user_id", %{some: :assign})
      |> subscribe_and_join(MemoryWeb.GameChannel, "game:lobby")

    {:ok, socket: socket}
  end

  test "show replies with status ok", %{socket: socket} do
    ref = push socket, "show", %{"x" => 1, "y" => 1}
    assert_reply ref, :ok, %{}
  end

  test "get_view replies with status ok", %{socket: socket} do
    ref = push socket, "get_view", %{"x" => 1, "y" => 1}
    assert_reply ref, :ok, %{}
  end

  test "reset replies with status ok", %{socket: socket} do
    ref = push socket, "reset", %{"x" => 1, "y" => 1}
    assert_reply ref, :ok, %{}
  end
end
