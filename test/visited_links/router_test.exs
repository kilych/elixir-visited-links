defmodule VisitedLinks.RouterTest do
	use ExUnit.Case
  use Plug.Test

  alias VisitedLinks.Router
  alias VisitedLinks.Repository, as: Repo
  alias VisitedLinks.Helper, as: Time
  alias VisitedLinks.Plug.EnsureParams.RequiredParamMissingOrEmptyError

  @opts Router.init([])

  @links [
    %{link: "https://redis.io", time: {{2001, 5, 16}, {13, 0, 8}}},
    %{link: "hexlet.com/courses/search?q=#", time: {{1986, 5, 16}, {23, 59, 59}}},
    %{link: "mit.edu", time: {{1970, 1, 1}, {0, 0, 0}}},
    %{link: "http://redis.io#fragment", time: {{1900, 5, 16}, {0, 34, 21}}}
  ]
  |> Enum.map(& %{&1 | time: Time.erl_to_unix(&1[:time])})

  setup_all do
    Repo.delete_all()
    Repo.insert_mul(@links)

    {:ok, %{}}
  end

  test "inserts links" do
    body = Poison.encode!(%{links: ["example.com", "https://ya.ru", "google.com/search?q=", "http://example.com#fragment"]})
    conn =
      :post
      |> conn("/visited_links", body)
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == ~S({"status":"ok"})
  end

  test "queries domains" do
    from = Time.erl_to_unix({{1979, 1, 1}, {0, 0, 0}})
    to = Time.now() - 1000
    conn =
      :get
      |> conn("/visited_domains?from=#{from}&to=#{to}")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == ~S({"status":"ok","domains":["hexlet.com","redis.io"]})
  end

  test "queries domains when required param is missing" do
    assert_raise RequiredParamMissingOrEmptyError, fn ->
      from = Time.erl_to_unix({{1979, 1, 1}, {0, 0, 0}})

      conn(:get, "/visited_domains?from=#{from}")
      |> Router.call(@opts)
    end

    assert_received {:plug_conn, :sent}
    assert_received {_ref, {status, _headers, message}}

    assert status == 400
    assert message == ~S({"status":"Required param 'to' is missing or empty."})
  end

  test "queries domains when required params are empty" do
    assert_raise RequiredParamMissingOrEmptyError, fn ->
      conn(:get, "/visited_domains?from=&to")
      |> Router.call(@opts)
    end

    assert_received {:plug_conn, :sent}
    assert_received {_ref, {status, _headers, message}}

    assert status == 400
    assert message == ~S({"status":"Required params 'from', 'to' are missing or empty."})
  end

  test "queries domains don't meet the criteria" do
    from = Time.now() + 10_000
    to = Time.now() + 20_000
    conn =
      :get
      |> conn("/visited_domains?from=#{from}&to=#{to}")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == ~S({"status":"ok","domains":[]})
  end

  test "returns 404" do
    conn = 
      :get
      |> conn("/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == ~S({"status":"Not found."})
  end
end
