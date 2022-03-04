defmodule Exsemnesia.Utils do
  @moduledoc """
  Utilities for the Mnesia database to make things easier.
  """
  require Exsemnesia.Handle128

  @max_login_lasts 60

  def shuffle_invite do
    :persistent_term.put(
      :exsemantica_invite,
      Base.encode64(:crypto.hash(:sha3_256, :crypto.strong_rand_bytes(32)))
    )
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

  def create_user(raw_handle, hash, invite_code) do
    invite = :persistent_term.get(:exsemantica_invite)

    cond do
      invite != invite_code ->
        {:error, :einvite}

      not Exsemnesia.Handle128.is_valid(raw_handle) ->
        {:error, :einval}

      true ->
        handle = Exsemnesia.Handle128.serialize(raw_handle)

        if unique?(handle) do
          shuffle_invite()
          id = increment(:id_count)

          {:ok, pk, sk} = Salty.Sign.Ed25519.keypair()
          date = DateTime.utc_now()

          # The JSON PASETOs MUST match, database on the server + the client
          {:ok, json} =
            Jason.encode(%{
              iss: ExsemanticaWeb.Endpoint.host(),
              aud: handle,
              exp: date |> DateTime.add(@max_login_lasts, :minute) |> DateTime.to_iso8601(),
              iat: date |> DateTime.to_iso8601()
            })

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
              info: {:auth, handle, hash, json, sk},
              idh: nil
            }
          ]
          |> Exsemnesia.Database.transaction()

          # Server has secret, client can run off with public.
          {:ok,
           %{
             idx: id,
             handle: handle,
             public_key: pk,
             paseto: Paseto.generate_token("v2", "public", json, {pk, sk})
           }}
        else
          {:error, :eusers}
        end
    end
  end

  # ============================================================================
  # Put items
  # ============================================================================
  # TODO: Clean these up into generate_ functions, so we can just do it in a go
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
