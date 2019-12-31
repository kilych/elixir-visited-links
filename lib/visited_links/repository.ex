defmodule VisitedLinks.Repository do
  alias VisitedLinks.Helper

  def insert_mul(links) do
    commands = links
    |> Enum.map(&make_insert_command/1)

    Redix.pipeline(:redix, commands)
  end

  def query(from, to) do
    commands =
      make_key_range(from, to)
      |> Enum.map(fn (args) -> make_query_command(args) end)

    Redix.pipeline!(:redix, commands)
    |> List.flatten()
    |> Enum.map(&Poison.decode!/1)
    |> Enum.map(fn ([time, link]) -> %{time: time, link: link} end)
  end

  def delete_all() do
    chunk_size = 100
    commands =
      fetch_all_keys()
      |> Enum.chunk_every(chunk_size)
      |> Enum.map(& ["DEL" | &1])

    (commands != []) && Redix.pipeline!(:redix, commands)
  end

  defp make_insert_command(%{link: link, time: time}) do
    {key_parts, score} = key_parts_and_score(time)
    key = make_key(key_parts)
    value = Poison.encode!([time,link])

    ["ZADD", key, score, value]
  end

  defp make_key_range(from, to) do
    {[from_year], from_score} = key_parts_and_score(from)
    {[to_year], to_score} = key_parts_and_score(to)

    case (to_year - from_year) do
      0 -> [{[from_year], from_score, to_score}]
      1 -> [{[from_year], from_score}, {[to_year], nil, to_score}]
      x when x >= 2
        -> [{[from_year], from_score}
           | (from_year + 1)..(to_year - 1) |> Enum.map(& {[&1]})]
        ++ [{[to_year], nil, to_score}]
    end
  end

  defp make_query_command({key_parts, min_score, max_score}) do
    key = make_key(key_parts)
    ["ZRANGEBYSCORE", key, min_score || "-inf", max_score || "+inf"]
  end

  defp make_query_command({key_parts, min_score}) do
    key = make_key(key_parts)
    ["ZRANGEBYSCORE", key, min_score || "-inf", "+inf"]
  end

  defp make_query_command({key_parts}) do
    key = make_key(key_parts)
    ["ZRANGE", key, 0, -1]
  end

  defp key_parts_and_score(time) do
    {{year, _, _}, _} = Helper.Time.unix_to_erl(time)

    beginning_of_year = {{year, 1, 1}, {0, 0, 0}}
    |> Helper.Time.erl_to_unix()

    seconds = time - beginning_of_year

    {[year], seconds}
  end

  defp make_key(key_parts), do: Enum.join([root_key() | key_parts], ":")

  def fetch_all_keys(cursor \\ 0, acc \\ []) do
    [cursor, keys] = Redix.command!(:redix, ["SCAN", cursor, "MATCH", "#{root_key()}:*"])
    case cursor do
      "0" -> acc ++ keys
      _ -> fetch_all_keys(cursor, acc ++ keys)
    end
  end

  defp root_key(), do: Application.get_env(:visited_links, :redis_root_key, "visited_links")
end
