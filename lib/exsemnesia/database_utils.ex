defmodule Exsemnesia.Utils do
  @moduledoc """
  Utilities for the Mnesia database to make things easier.
  """
  require Exsemnesia.Handle128
  require Logger

  @max_login_lasts 3600

  @doc """
  Generates a nonce into the database given a Handle128 as its argument.
  """
  def generate_nonce(handle) do
    nonce = Base.url_encode64(:crypto.strong_rand_bytes(32))
    {:ok, pk, sk} = Salty.Sign.Ed25519.keypair()

    Logger.notice("Password for #{handle} is now '#{nonce}'")

    [%{operation: :put, table: :auth, info: {:auth, handle, Argon2.add_hash(nonce), {pk, sk}}}]
    |> Exsemnesia.Database.transaction()
  end

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

  # ============================================================================
  # User authentication
  # ============================================================================
  def check_user(raw_handle, paseto) do
    Logger.debug("Trying check PASETO for #{raw_handle}")

    cond do
      not Exsemnesia.Handle128.is_valid(raw_handle) ->
        Logger.info("Trying check PASETO for #{raw_handle} FAILED: Invalid handle")
        {:error, :einval}

      true ->
        handle = Exsemnesia.Handle128.serialize(raw_handle)

        {:atomic, [auth, auth_state]} =
          [Exsemnesia.Utils.get(:auth, handle), Exsemnesia.Utils.get(:auth_state, handle)]
          |> Exsemnesia.Database.transaction()

        # TODO: Better error handling below
        {:ok, token} =
          Paseto.parse_token(
            paseto,
            case auth.response do
              [{:auth, _secret, keypair}] -> keypair
              _ -> nil
            end
          )

        {:ok, decoded} = Jason.decode(token.payload)
        # TODO: Better error handling above

        case auth_state.response do
          [] ->
            Logger.info(
              "Trying check PASETO for #{raw_handle} as #{handle} FAILED: No PASETO on server"
            )

            {:error, :enoent}

          [{:auth_state, paseto}] when paseto === decoded ->
            Logger.info("Trying check PASETO for #{raw_handle} as #{handle} SUCCESS")
        end
    end
  end

  def create_user(raw_handle, password) do
    Logger.debug("Trying activating #{raw_handle}")

    cond do
      not Exsemnesia.Handle128.is_valid(raw_handle) ->
        Logger.info("Trying activating #{raw_handle} FAILED: Invalid handle")
        {:error, :einval}

      true ->
        handle = Exsemnesia.Handle128.serialize(raw_handle)

        if unique?(handle) do
          id = increment(:id_count)

          {:atomic, user} =
            [Exsemnesia.Utils.get(:auth, handle)] |> Exsemnesia.Database.transaction()

          case user.response do
            [] ->
              Logger.info("Trying activating #{raw_handle} FAILED: Access denied")
              {:error, :eacces}

            [{:auth, ^handle, secret, keypair}] ->
              case Argon2.check_pass(secret, pass) do
                {:ok, _} ->
                  date = DateTime.utc_now()

                  # The JSON PASETOs MUST match, database on the server + the client
                  {:ok, json} =
                    Jason.encode(
                      paseto = %{
                        iss: ExsemanticaWeb.Endpoint.host(),
                        aud: handle,
                        exp:
                          date
                          |> DateTime.add(@max_login_lasts, :second)
                          |> DateTime.to_iso8601(),
                        iat: date |> DateTime.to_iso8601(),
                        exs_kid: Base.url_encode64(:crypto.strong_rand_bytes(32)),
                        exs_uid: handle
                      }
                    )

                  [
                    %{
                      operation: :put,
                      table: :users,
                      info: {:users, id, date, handle, <<0::128>>},
                      idh: {id, handle}
                    }
                  ]
                  |> Exsemnesia.Database.transaction()

                  # Server has secret, client can run off with public.
                  {:ok, parsed} = Paseto.generate_token("v2", "public", json, keypair)
                  Logger.info("Trying activating #{raw_handle} as #{handle} SUCCESS")

                  {:ok,
                   %{
                     handle: handle,
                     paseto: parsed
                   }}

                {:error, err} ->
                  Logger.warning(
                    "Trying activating #{raw_handle} as #{handle} FAILED: argon2 - '#{err}'"
                  )

                  {:error, :eacces}
              end
          end
        else
          Logger.info("Trying activating #{raw_handle} as #{handle} FAILED: Not a unique handle")
          {:error, :eusers}
        end
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

        {:atomic, head} =
          [Exsemnesia.Utils.get(:auth, handle)] |> Exsemnesia.Database.transaction()

        case head.response do
          [] ->
            Logger.info("Trying logging in #{raw_handle} as #{handle} FAILED: No such handle")
            {:error, :enoent}

          [{:auth, ^handle, secret, keypair}] ->
            date = DateTime.utc_now()

            {:ok, json} =
              Jason.encode(
                paseto = %{
                  iss: ExsemanticaWeb.Endpoint.host(),
                  aud: handle,
                  exp: date |> DateTime.add(@max_login_lasts, :second) |> DateTime.to_iso8601(),
                  iat: date |> DateTime.to_iso8601(),
                  exs_kid: Base.url_encode64(:crypto.strong_rand_bytes(32)),
                  exs_uid: handle
                }
              )

            [
              %{
                operation: :put,
                table: :auth_state,
                info: {:auth_state, handle, paseto},
                idh: nil
              }
            ]
            |> Exsemnesia.Database.transaction()

            {:ok, parsed} =
              Paseto.generate_token(
                "v2",
                "public",
                json,
                keypair
              )

            Logger.info("Trying logging in #{raw_handle} as #{handle} SUCCESS")
            # Server has secret, client can run off with public.
            {:ok,
             %{
               handle: handle,
               paseto: parsed
             }}

          [{:auth, ^handle, _hash, _paseto, _sk}] ->
            Logger.info("Trying logging in #{raw_handle} as #{handle} FAILED: Incorrect password")

            {:error, :eacces}
        end
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

        %{
          operation: :put,
          table: :posts,
          info: {:posts, id, DateTime.utc_now(), handle, title, content, user},
          idh: {id, handle}
        }
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

        %{
          operation: :put,
          table: :interests,
          info: {:interests, id, DateTime.utc_now(), title, content, related_to},
          idh: {id, handle}
        }
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
  def get(table, idx) do
    %{
      operation: :get,
      table: table,
      info: idx
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
    {:atomic, uniqs} =
      [
        Exsemnesia.Utils.count(:users, :handle, handle),
        Exsemnesia.Utils.count(:posts, :handle, handle),
        Exsemnesia.Utils.count(:interests, :handle, handle)
      ]
      |> Exsemnesia.Database.transaction()

    uniqs
    |> Enum.map(fn %{operation: :count, table: _table, info: _info, response: response} ->
      response
    end)
    |> Enum.sum() == 0
  end
end
