defmodule VisitedLinks.Plug.EnsureParams do
	defmodule RequiredParamMissingOrEmptyError do
	  @moduledoc """
    Error raised when a required param is missing.
    """

    defexception message: "", plug_status: 400
  end

  def init(opts), do: opts

  def call(conn, opts) do
    ensure_params!(conn, opts)
  end

  defp ensure_params!(%{params: params, request_path: path} = conn, opts) do
    with pathes = [_|_] <- opts[:pathes],
         fields = [_|_] <- opts[:fields]
      do

      if path in pathes do
        given_fields = Map.keys(params)
        missing = fields -- given_fields

        empty =
          params
          |> Enum.filter(& elem(&1, 1) in [nil, ""])
          |> Keyword.keys()

        invalid = missing ++ empty

        case invalid do
          [] -> nil
          [field] ->
            raise RequiredParamMissingOrEmptyError,
                  "Required param '#{field}' is missing or empty."
          _ ->
            raise RequiredParamMissingOrEmptyError,
                  "Required params '#{Enum.join(invalid, ~S(', '))}' are missing or empty."
        end
      end
    end

    conn
  end
end
