defmodule VisitedLinks.HelperTest do
	use ExUnit.Case

  alias VisitedLinks.Helper

  test "extracts domain from empty string" do
    assert nil == Helper.extract_domain("")
  end

  test "extracts domain from url with scheme" do
    assert "redis.io" == Helper.extract_domain("https://redis.io")
  end

  test "extracts domain from url with bad scheme" do
    assert "mongo.db" == Helper.extract_domain("https:/mongo.db")
    assert "http" == Helper.extract_domain("http//my.sql")
  end

  test "extracts domain from host" do
    assert "boston.dynamics" == Helper.extract_domain("boston.dynamics")
    assert "oxford.co.uk" == Helper.extract_domain("oxford.co.uk")
  end

  test "extracts domain from url with path and fragment" do
    assert "hexdocs.pm" == Helper.extract_domain("hexdocs.pm/elixir/Enum.html#at/3")
  end

  test "extracts domain from url with query" do
    assert "www.youtube.com" ==
      Helper.extract_domain("https://www.youtube.com/results?search_query=quake+champions")
  end

  test "extracts domain from single path" do
    assert "long" == Helper.extract_domain("/long/way/to/the/top")
  end
end
