defmodule VisitedLinks.Helper do
  def extract_domain(link) when is_binary(link) do
    case %{host: host, path: path} = URI.parse(link) do
      %{host: nil, path: nil} -> nil
      %{host: nil} ->
        path
        |> String.trim_leading("/")
        |> String.split("/")
        |> Enum.at(0)
      _ -> host
    end 
  end

  def now() do
    {:ok, now} = DateTime.now(time_zone())
    DateTime.to_unix(now)
  end

  def unix_to_erl(time) when is_integer(time) do
    time
    |> DateTime.from_unix!()
    |> DateTime.to_naive()
    |> NaiveDateTime.to_erl()
  end

  def erl_to_unix(time) do
    time
    |> NaiveDateTime.from_erl!()
    |> DateTime.from_naive!(time_zone())
    |> DateTime.to_unix()
  end

  defp time_zone(), do: "Etc/UTC"
end
