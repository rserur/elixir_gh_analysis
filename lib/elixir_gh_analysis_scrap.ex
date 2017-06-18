# defmodule ElixirGHAnalysis do
#   # @moduledoc """
#   # Documentation for ElixirGHAnalysis.
#   # """
#   #
#   # @doc """
#   # Hello world.
#   #
#   # ## Examples
#   #
#   #     iex> ElixirGHAnalysis.hello
#   #     :world
#   #
#   # """
#   # def psuedocode do
#   #   url = "https://api.github.com/graphql"
#   #   headers = ["Authorization": "bearer ''"]
#   #   # query =  %{"query": "query { viewer { login }}"}
#   #   graph_query = """
#   #     query SearchMostTop10Star($queryString: String!, $afterString: String) {
#   #       search(query: $queryString, type: REPOSITORY, first: 100, after: $afterString) {
#   #         repositoryCount
#   #         edges {
#   #           node {
#   #             ... on Repository {
#   #               owner {
#   #                 ... on User {
#   #                   name
#   #                 }
#   #               }
#   #             }
#   #           }
#   #         }
#   #         pageInfo {
#   #           endCursor
#   #         }
#   #       }
#   #     }
#   #   """
#   #   languages = ["elixir", "erlang", "ruby", "javascript", "python", "go", "haskell", "clojure"]
#   #   # elixir 2,124
#   #   # erlang 2,242
#   #   # ruby 38,802
#   #   # js 181,304
#   #   # python 104,549
#   #   # go 21,677
#   #   # haskell 5,812
#   #   # clojure 5,816
#   #
#   #   params = %{"queryString": "stars:>=4 created:>=2011-01-01 language:elixir" }
#   #     # "afterString": "Y3Vyc29yOjEwMA"
#   #   body = %{"query": graph_query, "variables": Poison.encode!(params)}
#   #
#   #   case HTTPoison.post(url, Poison.encode!(body), headers) do
#   #     {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
#   #       response = Poison.decode!(body)
#   #       # get_in(response, ["data", "search", "edges"]) or
#   #       # response["data"]["search"]["edges"] --> list of repos -->
#   #       #  %{"node":
#   #       #      "owner": %{"name": OWNER NAME},
#   #       #      "primaryLanguage": %{"name": LANGUAGE NAME}
#   #       #   }
#   #
#   #       # response["data"]["search"]["pageInfo"]["endCursor"] --> string for $afterString
#   #       # or get_in(response, ["data", "search", "pageInfo", "endCursor"])
#   #
#   #       repos = Enum.map(repos, fn (repo) ->
#   #         %{
#   #           name: repo["node"]["owner"]["name"],
#   #           language: repo["node"]["primaryLanguage"]["name"]
#   #         }
#   #       end )
#   #
#   #       # save repos to db
#   #
#   #       # if headers "X-RateLimit-Remaining" > 1, move afterString to last ID found in body
#   #       # if headers  "X-RateLimit-Reset" 0, sleep until reset
#   #     {:error, %HTTPoison.Response{status_code: 500, body: body, headers: headers}} ->
#   #       Poison.decode!(body)
#   #   end
#   # end
#
# end
