defmodule ExsemanticaWeb.APIv0.Bucket do
  @moduledoc """
  Assigns profile pictures with users, posts, and interests.
  """
  use ExsemanticaWeb, :controller

  require Exsemnesia.Handle128

  @doc """
  Creates a profile picture. Returns the ID if successful.
  """
  def create(conn, _opts) do
    conn
  end

  @doc """
  Shows a profile picture. Returns it raw if successful.
  """
  def show(conn, _opts) do
    conn
  end

  @doc """
  Updates a profile picture.
  """
  def update(conn, _opts) do
    conn
  end

  @doc """
  Deletes a profile picture.
  """
  def delete(conn, _opts) do
    conn
  end
end
