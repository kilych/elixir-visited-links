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
end
