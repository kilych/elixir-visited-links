defmodule VisitedLinks.Plug.ValidateParams do
	defmodule MissingParamError do
	  @moduledoc """
    Error raised when a required param is missing.
    """

    defexception message: "", plug_status: 400
  end

	defmodule InvalidParamError do
	  @moduledoc """
    Error raised when a required param is invalid.
    """

    defexception message: "", plug_status: 400
  end

  def init(opts), do: opts

  def call(conn, opts) do
    validate_params!(conn, opts)
  end

  defp validate_params!(%{params: params, request_path: path} = conn, opts) do
    with pathes = [_|_] <- opts[:pathes] do
      if path in pathes do
        fields = Keyword.get(opts, :fields, [])
        validators = Keyword.get(opts, :validators, [])

        ensure_required!(fields, params)
        ensure_valid!(fields, validators, params)
      end
    end

    conn
  end

  def is_not_empty(value), do: value && !(value in ["", []])
  def represents_integer(value) do
    is_binary(value) && !match?(:error, Integer.parse(value))
  end

  defp ensure_required!(fields, params) do
    given_fields = Map.keys(params)
    missing = fields -- given_fields

    if missing != [] do
      raise MissingParamError, make_error_message(missing, :missing)
    end
  end

  defp ensure_valid!(fields, validators, params) do
    invalid =
      params
      |> Map.take(fields)
      |> Enum.reject(fn {_, value} ->
        Enum.all?(validators, & validate(&1, value))
      end)
      |> Keyword.keys()

    if invalid != [] do
      raise InvalidParamError, make_error_message(invalid, :invalid)
    end
  end

  defp validate(validator, value) when is_function(validator, 1) do
    validator.(value)
  end

  defp validate(validator, value) when is_atom(validator) do
    apply(__MODULE__, validator, [value])
  end

  defp make_error_message([field], kind), do: "Param '#{field}' is #{kind}."
  defp make_error_message([_|_] = fields, kind) do
    "Params '#{Enum.join(fields, ~S(', '))}' are #{kind}."
  end
end
