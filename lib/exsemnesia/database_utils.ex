defmodule Exsemnesia.Utils do
  @moduledoc """
  Utilities for the Mnesia database to make things easier.
  """
  require Exsemnesia.Handle128
  require Logger

  @salsa "auth"
  @max_login_lasts 3600

  def increment(type) do
    cnt = :mnesia.dirty_update_counter(:counters, type, 1)
    <<cnt::128>>
  end

  def increment_popularity(table, idx) do
    %{
      operation: :rank,
      table: table,
      info: %{idx: idx, inc: 1}
    }
  end

  def do_case(lc_handle) do
    %{
      operation: :index,
      table: :lowercases,
      info: %{key: :lowercase, value: Exsemnesia.Handle128.serialize(lc_handle)}
    }
  end

  # ============================================================================
  # User authentication
  # ============================================================================
  def check_user(raw_handle, token_in) do
    Logger.debug("Trying check Phoenix token for #{raw_handle}")

    cond do
      not Exsemnesia.Handle128.is_valid(raw_handle) ->
        Logger.debug("Trying check Phoenix token for #{raw_handle} FAILED: Invalid handle")
        {:error, :einval}

      true ->
        handle = Exsemnesia.Handle128.serialize(raw_handle)
        downcased = String.downcase(handle, :ascii)

        {:atomic, [auth]} =
          [Exsemnesia.Utils.get(:auth, downcased)]
          |> Exsemnesia.Database.transaction("check Phoenix token for user '#{handle}'")

        token =
          case auth.response do
            [] -> nil
            [{:auth, _handle, _secret, token}] -> token
          end

        case Phoenix.Token.verify(ExsemanticaWeb.Endpoint, "auth", token_in) do
          {:ok, ^token} ->
            Logger.debug("Trying check Phoenix token for #{raw_handle} SUCCESS")
            true

          error ->
            Logger.debug("Trying check Phoenix token for #{raw_handle} FAILED: #{inspect(error)}")
            false
        end
    end
  end
  def create_user(raw_handle, password) do
    Logger.debug("Trying activating #{raw_handle}")

    handle = Exsemnesia.Handle128.serialize(raw_handle)
    unique? = Exsemnesia.Utils.unique?(handle)

    if unique? do
      id = increment(:id_count)

      secret = Argon2.add_hash(password)
      date = DateTime.utc_now()

      [
        %{
          operation: :put,
          table: :users,
          info: {:users, id, date, handle, <<0::128>>},
          idh: {id, handle}
        },
        %{
          operation: :put,
          table: :auth,
          # We don't need a token here yet
          info: {:auth, String.downcase(handle, :ascii), secret, nil}
        }
      ]
      |> Exsemnesia.Database.transaction("create user + downcasing")

      {:ok, token} = regenerate_token(handle)

      Logger.info("Trying activating #{raw_handle} as #{handle} SUCCESS")
      :persistent_term.put(:exseminvite, :crypto.strong_rand_bytes(24))

      {:ok,
       %{
         handle: handle,
         token: token
       }}
    else
      Logger.info("Trying activating #{raw_handle} as #{handle} FAILED: Not a unique handle")
      {:error, :eusers}
    end
  end

  def login_user(raw_handle, password) do
    Logger.debug("Trying logging in #{raw_handle}")

    cond do
      not Exsemnesia.Handle128.is_valid(raw_handle) ->
        Logger.info("Trying logging in #{raw_handle} FAILED: Invalid handle")
        {:error, :einval}

      true ->
        handle = Exsemnesia.Handle128.serialize(raw_handle)

        {:atomic, [head]} =
          [Exsemnesia.Utils.get(:auth, String.downcase(handle, :ascii))]
          |> Exsemnesia.Database.transaction("try to log in to HTTP")

        case head.response do
          [] ->
            Logger.info("Trying logging in #{raw_handle} as #{handle} FAILED: No such handle")
            {:error, :enoent}

          [{:auth, handle, secret, _token}] ->
            case Argon2.check_pass(secret, password) do
              {:ok, _} ->
                Logger.info("Trying logging in #{raw_handle} as #{handle} SUCCESS")
                Exsemnesia.Utils.regenerate_token(handle)

              {:error, err} ->
                Logger.warning(
                  "Trying logging in #{raw_handle} as #{handle} FAILED: argon2 - '#{err}'"
                )

                {:error, :eacces}
            end
        end
    end
  end

  def regenerate_token(handle) do
    Logger.debug("Trying regenerate token for #{handle}")

    {:atomic, [head]} =
      [Exsemnesia.Utils.get(:auth, String.downcase(handle, :ascii))]
      |> Exsemnesia.Database.transaction("try to get data to regenerate token")

    case head.response do
      [] ->
        Logger.info("Trying regenerate token for #{handle} FAILED: No such handle")
        {:error, :enoent}

      [{:auth, handle, secret, _token}] ->
        Logger.info("Trying regenerate token #{handle} SUCCESS")

        token =
          Phoenix.Token.sign(ExsemanticaWeb.Endpoint, @salsa, :crypto.strong_rand_bytes(32),
            max_age: @max_login_lasts
          )

        [%{operation: :put, table: :auth, info: {:auth, handle, secret, token}, idh: nil}]
        |> Exsemnesia.Database.transaction("put in regenerated token")

        {:ok, %{handle: handle, token: token}}
    end
  end

  # ============================================================================
  # Put items
  # ============================================================================
  # TODO: Clean these up into create_ functions, so we can just do it in a go
  # I mean like make it so that each function calls the transaction predefined
  def put_post(raw_handle, title, content, user) do
    if Exsemnesia.Handle128.is_valid(raw_handle) do
      handle = Exsemnesia.Handle128.serialize(raw_handle)

      if unique?(handle) do
        id = increment(:id_count)
        downcased = String.downcase(handle, :ascii)

        [
          %{
            operation: :put,
            table: :lowercases,
            info: {:lowercases, handle, downcased},
            idh: nil
          },
          %{
            operation: :put,
            table: :posts,
            info: {:posts, id, DateTime.utc_now(), handle, title, content, user},
            idh: {id, handle}
          }
        ]
      else
        {:error, :eusers}
      end
    else
      {:error, :einval}
    end
  end

  def put_interest(raw_handle, title, content, related_to) do
    if Exsemnesia.Handle128.is_valid(raw_handle) do
      handle = Exsemnesia.Handle128.serialize(raw_handle)

      if unique?(handle) do
        id = increment(:id_count)
        downcased = String.downcase(handle, :ascii)

        [
          %{
            operation: :put,
            table: :lowercases,
            info: {:lowercases, handle, downcased},
            idh: nil
          },
          %{
            operation: :put,
            table: :interests,
            info: {:interests, id, DateTime.utc_now(), handle, title, content, related_to},
            idh: {id, handle}
          }
        ]
      else
        {:error, :eusers}
      end
    else
      {:error, :einval}
    end
  end

  # ============================================================================
  # Get items
  # ============================================================================
  @doc """
  Gets an entry by its node ID.
  """
  def get(table, idx) do
    %{
      operation: :get,
      table: table,
      info: idx
    }
  end

  @doc """
  Looks up by handle. Only works with :users, :posts, and :interests tables.
  """
  def get_by_handle(table, handle) do
    %{
      operation: :index,
      table: table,
      info: %{key: :handle, value: handle}
    }
  end

  @doc """
  Looks up the lowercase to its original case.
  """
  def get_recase(lower) do
    %{
      operation: :index,
      table: :lowercases,
      info: %{key: :lowercase, value: lower}
    }
  end

  def count(table, key, value) do
    %{
      operation: :count,
      table: table,
      info: %{key: key, value: value}
    }
  end

  def trending(count) do
    %{
      operation: :tail,
      table: :ctrending,
      info: count
    }
  end

  def unique?(handle) do
    handle = String.downcase(handle, :ascii)

    {:atomic, uniqs} =
      [
        Exsemnesia.Utils.count(:lowercases, :lowercase, handle)
      ]
      |> Exsemnesia.Database.transaction("uniqueness")

    uniqs
    |> Enum.map(fn %{operation: :count, table: _table, info: _info, response: response} ->
      response
    end)
    |> Enum.sum() == 0
  end
end
