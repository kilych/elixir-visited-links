defmodule VisitedLinks.Router do
	use Plug.Router

  if Mix.env() == :dev do
    use Plug.Debugger
  end

  use Plug.ErrorHandler

  alias VisitedLinks.Repository, as: Repo
  alias VisitedLinks.Helper
  alias VisitedLinks.Plug.EnsureParams

  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug EnsureParams, pathes: ["/visited_domains"], fields: ["from", "to"]
  plug :match
  plug :dispatch

  post "/visited_links" do
    time = Helper.now()
    links =
      Map.get(conn.body_params, "links", [])
      |> Enum.map(& %{link: &1, time: time})

    Repo.insert_mul(links)

    message = Poison.encode!(%{status: "ok"})
    send_resp(conn, 200, message)
  end

  get "/visited_domains" do
    from = String.to_integer(conn.params["from"])
    to = String.to_integer(conn.params["to"])

    domains =
      Repo.query(from, to)
      |> Enum.map(& &1.link)
      |> Enum.map(&Helper.extract_domain/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    message = Poison.encode!(%{domains: domains, status: "ok"})
    send_resp(conn, 200, message)
  end

  match _ do
    message = Poison.encode!(%{status: "Not found."})
    send_resp(conn, 404, message)
  end

  defp handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    IO.inspect(kind, label: :kind)
    IO.inspect(reason, label: :reason)
    IO.inspect(stack, label: :stack)

    body =
      case reason do
        %EnsureParams.RequiredParamMissingOrEmptyError{message: message} -> message
        _ -> "Something went wrong."
      end
      |> (& Poison.encode!(%{status: &1})).()

    send_resp(conn, conn.status, body)
  end
end
