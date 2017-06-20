defmodule ElixirGHAnalysis.Search do
  defstruct [:language, :has_next_page, :cursor, :reset_time,
  :variables, :requests_remaining, :results,
  query: """
    query($queryString: String!, $afterString: String) {
      search(query: $queryString, type: REPOSITORY, first: 100, after: $afterString) {
        repositoryCount
        edges { node { ... on Repository { primaryLanguage { name } owner { ... on User { name } } } } }
        pageInfo { endCursor hasNextPage }
      } }
  """]
end
