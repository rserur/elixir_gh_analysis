defmodule ElixirGHAnalysis do
  use Application

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
      ElixirGHAnalysis.search_by_language(language)
    end
  end

  def search_by_language(language) do
    language
    |> ElixirGHAnalysis.build_variables
    |> ElixirGHAnalysis.build_query
    |> ElixirGHAnalysis.make_request
  end

  def build_variables(language) do
    IO.puts "building variables with #{language}..."
    %{"queryString": "stars:>=4 created:>=2011-01-01 language:#{language}" }
  end

  def build_variables(language, cursor) do
    IO.puts "building variables with #{language} and cursor #{cursor}..."
    %{ "queryString": "stars:>=4 created:>=2011-01-01 language:#{language}",
      "$afterString": "#{cursor}" }
  end

  def build_query(variables) do
    IO.puts "building query..."

    base_query = """
      query($queryString: String!, $afterString: String) {
        search(query: $queryString, type: REPOSITORY, first: 100, after: $afterString) {
          repositoryCount
          edges { node { ... on Repository { primaryLanguage { name } owner { ... on User { name } } } } }
          pageInfo { endCursor }
        } }
    """

    %{ "query": base_query, "variables": Poison.encode!(variables) }
  end

  def make_request(query) do
    url = "https://api.github.com/graphql"
    token =  System.get_env(GITHUB_API_TOKEN)
    headers = ["Authorization": "bearer #{token}"]

    IO.puts "making request..."

    case HTTPoison.post(url, Poison.encode!(query), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
        Poison.decode!(body)
        |> get_in(["data", "search", "edges"])
        |> save_developers
      {:error, %HTTPoison.Response{status_code: 500, body: body, headers: headers}} ->
        Poison.decode!(body)
    end
  end

  # ElixirGHAnalysis.record_data(['elixir', 'ruby'])
  # ElixirGHAnalysis.Repo.all(ElixirGHAnalysis.Developer)
  # run source .env in your shell before you run any iex or mix commands.

  def save_developers(repos) do
    Enum.each repos, fn repo ->
      name = repo["node"]["owner"]["name"]
      language = repo["node"]["primaryLanguage"]["name"]
      unless is_nil(name) || is_nil(language) do
        IO.puts "saving #{name} for #{language}..."

        existing_developer = case ElixirGHAnalysis.Repo.get_by(ElixirGHAnalysis.Developer, name: name, language: language) do
          nil -> %ElixirGHAnalysis.Developer{name: name, language: language, repository_count: 1}
          developer -> developer
        end

        repository_count = existing_developer.repository_count + 1

        existing_developer
        |> ElixirGHAnalysis.Developer.changeset(%{ name: name, language: language, repository: repository_count })
        |> ElixirGHAnalysis.Repo.insert_or_update
      end
    end
  end

  # def developers do
  #   Developer
  #   |> Repo.all
  # end
end
