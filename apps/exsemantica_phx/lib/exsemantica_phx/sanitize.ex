defmodule ExsemanticaPhx.Sanitize do
  def valid_interest?(title) do
    not Regex.match?(~r/[^A-Za-z0-9\_]/, title)
  end

  def valid_username?(username) do
    not Regex.match?(~r/[^A-Za-z0-9\_]/, username)
  end

  def valid_email?(email) do
    # Regular filtering right now.
    if EmailChecker.valid?(email) do
      # Abuse testing, this e-mail is valid but a script kiddie may be abusing
      # it.

      # This is hard. First determine if there are slashes at the beginning.
      email_valid = not Regex.match?(~r/\//, email)

      # HACK: We know it may be safe for us to parse. If it isn't please open an
      # issue and we can sort out a new parser.
      #
      # Elixir can parse e-mail-like identifiers with two leading slashes.
      email_ir0 =
        cond do
          email_valid -> URI.parse("//" <> email)
          true -> nil
        end

      # There was a trick floating around that people could dot their e-mails on
      # Gmail or something to evade account restrictions elsewhere.
      #
      # Don't do that here.
      not (Regex.match?(~r/\@/, email_ir0.userinfo) or
             Regex.match?(~r/\@/, email_ir0.host) or
             String.starts_with?(email_ir0.userinfo, ".") or
             String.ends_with?(email_ir0.userinfo, ".") or
             String.starts_with?(email_ir0.host, ".") or
             String.ends_with?(email_ir0.host, "."))
    else
      false
    end
  end
  
  def truncate_string(str, str_length_max) do
    # UTF-8 safe
    string_length = String.length(str)
    cond do
      string_length > str_length_max ->
        String.slice(str, 0..(str_length_max - 1)) <> "..."
      true ->
        str
    end
  end
end
