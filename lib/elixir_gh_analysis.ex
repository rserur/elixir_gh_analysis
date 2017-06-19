defmodule ElixirGHAnalysis do
  use Application
  use Timex
  require IEx

  alias ElixirGHAnalysis.Repo
  alias ElixirGHAnalysis.Developer
  alias HTTPoison.Response

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(ElixirGHAnalysis.Repo, [])
      # Starts a worker by calling: TestSuper.Worker.start_link(arg1, arg2, arg3)
      # worker(TestSuper.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TestSuper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def record_data(languages) do
    Enum.each languages, fn language ->
      ElixirGHAnalysis.search_by_language(%{ language: language, has_next_page: nil})
    end
  end

  def search_by_language(%{ language: language, has_next_page: nil}) do
    IO.puts "running first request for language #{language}..."
    language
    |> ElixirGHAnalysis.build_variables
    |> ElixirGHAnalysis.build_query
    |> ElixirGHAnalysis.make_request
    |> ElixirGHAnalysis.search_by_language
  end

  def search_by_language(results) do
    cond do
      results.has_next_page == false ->
        IO.puts "finished searching for #{results.language} repos..."
      results.requests >= 1 ->
        IO.puts "running another request for language #{results.language} repos..."
        results.language
        |> ElixirGHAnalysis.build_variables(results.cursor)
        |> ElixirGHAnalysis.build_query
        |> ElixirGHAnalysis.make_request
        |> ElixirGHAnalysis.search_by_language
      results.requests == 0 ->
        time_remaining = Timex.format(results.reset_time, "{relative}", :relative)
        IO.puts "Max requests reached. Waiting until rate limit expires #{time_remaining}..."

        Timex.diff(results.reset_time, Timex.now, :milliseconds)
        |> wait_then_run(results)
        |> ElixirGHAnalysis.search_by_language
    end
  end

  def build_variables(language) do
    IO.puts "building variables for #{language}..."
    %{"queryString": "stars:>=4 created:>=2011-01-01 language:#{language}" }
  end

  def build_variables(language, cursor) do
    IO.puts "building variables for #{language} at cursor #{cursor}..."
    %{ "queryString": "stars:>=4 created:>=2011-01-01 language:#{language}",
       "afterString": cursor
     }
  end

  def build_query(variables) do
    IO.puts "building query..."

    base_query = """
      query($queryString: String!, $afterString: String) {
        search(query: $queryString, type: REPOSITORY, first: 100, after: $afterString) {
          repositoryCount
          edges { node { ... on Repository { primaryLanguage { name } owner { ... on User { name } } } } }
          pageInfo { endCursor hasNextPage }
        } }
    """

    %{ "query": base_query, "variables": Poison.encode!(variables) }
  end

  def make_request(query) do
    url = "https://api.github.com/graphql"
    token =  System.get_env("GITHUB_API_TOKEN")
    request_headers = ["Authorization": "bearer #{token}"]

    IO.puts "making request..."

    case HTTPoison.post(url, Poison.encode!(query), request_headers) do
      {:ok, %Response{status_code: 200, body: body, headers: response_headers}} ->
        Poison.decode!(body)
        |> get_in(["data", "search"])
        |> save_developers(response_headers)
      {:error, %Response{status_code: 500, body: body, headers: response_headers}} ->
        Poison.decode!(body)
        IO.puts response_headers
    end
  end

  # ElixirGHAnalysis.record_data(['elixir', 'ruby'])
  # ElixirGHAnalysis.Repo.all(ElixirGHAnalysis.Developer)
  # run source .env in your shell before you run any iex or mix commands.

  def save_developers(search_results, response_headers) do
    case search_results["edges"] do
    nil ->
      IO.puts "No additional repos found..."
    _ ->
      Enum.each search_results["edges"], fn repo ->
        name = repo["node"]["owner"]["name"]
        language = repo["node"]["primaryLanguage"]["name"]
        unless is_nil(name) || is_nil(language) do
          IO.puts "saving #{name} for #{language}..."

          existing_developer = case Repo.get_by(Developer, name: name, language: language) do
            nil -> %Developer{name: name, language: language, repository_count: 1}
            developer -> developer
          end

          repository_count = existing_developer.repository_count + 1

          existing_developer
          |> Developer.changeset(%{ name: name, language: language, repository: repository_count })
          |> Repo.insert_or_update
        end
      end
    end

    %{ has_next_page: search_results["pageInfo"]["hasNextPage"],
      cursor: search_results["pageInfo"]["endCursor"],
      reset_time: ElixirGHAnalysis.get_reset_time(response_headers),
      requests: ElixirGHAnalysis.get_requests_remaining(response_headers),
      language: get_in(List.first(search_results["edges"]),["node", "primaryLanguage", "name"]) }
  end

  def get_reset_time(response_headers) do
    List.keyfind(response_headers, "X-RateLimit-Reset", 0)
    |> elem(1) |> Integer.parse |> elem(0) |> DateTime.from_unix |> elem(1)
  end

  def get_requests_remaining(response_headers) do
    List.keyfind(response_headers, "X-RateLimit-Remaining", 0) |> elem(1)
  end

  def wait_then_run(milliseconds, return_value) do
    if :timer.sleep(milliseconds) == :ok do
      return_value
    end
  end
  # def developers do
  #   Developer
  #   |> Repo.all
  # end
end
