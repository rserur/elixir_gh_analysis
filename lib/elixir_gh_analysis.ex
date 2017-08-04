defmodule ElixirGHAnalysis do
  use Application
  use Timex
  require IEx

  alias ElixirGHAnalysis
  alias ElixirGHAnalysis.Repo
  alias ElixirGHAnalysis.Search
  alias ElixirGHAnalysis.Developer
  alias HTTPoison.Response

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    IEx.pry

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Repo, []),
      worker(ElixirGHAnalysis.Searcher, _args)
      # Starts a worker by calling: TestSuper.Worker.start_link(arg1, arg2, arg3)
      # worker(TestSuper.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirGHAnalysis.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def record_data(language) do
    %Search{language: language, cursor: nil}
    |> add_variables
    |> execute_request
  end

  def execute_request(%Search{query: query, variables: variables, has_next_page: has_next_page,
  requests_remaining: requests_remaining, language: language,
  reset_time: reset_time} = search) do
    url = "https://api.github.com/graphql"
    token =  System.get_env("GITHUB_API_TOKEN")
    request_headers = ["Authorization": "bearer #{token}"]

    cond do
      has_next_page == false ->
        IO.puts "finished searching for #{language} language repos..."
      requests_remaining >= 1 ->
        IO.puts "running another request for #{language} language repos..."
        case HTTPoison.post(url, Poison.encode!(%{query: query, variables: variables}), request_headers) do
          {:ok, %Response{status_code: 200, body: body, headers: response_headers}} ->
            body = Poison.decode!(body) |> get_in(["data", "search"])
            %Search{search| results: %{body: body, response_headers: response_headers}}
            |> save_developers
            |> move_cursor
            |> add_next_page
            |> add_reset_time
            |> add_remaining_requests
            |> add_variables
            |> execute_request
          {_, %Response{status_code: 500}} ->
            %Search{search| results: %{body: :error}}
        end
      requests_remaining == 0 ->
        time_remaining = Timex.format(reset_time, "{relative}", :relative)
        IO.puts "Max requests reached. Waiting until rate limit expires #{time_remaining}..."
        Timex.diff(reset_time, Timex.now, :milliseconds)
        |> wait_then_run(search)
        |> add_variables
        |> execute_request
    end
  end

  def add_variables(%Search{language: language, cursor: cursor} = search) do
    IO.puts "adding language (#{language}) and cursor (#{cursor}) variables..."
    variables = %{ "queryString": "stars:>=4 created:>=2011-01-01 language:#{language}",
      "afterString": cursor }
    %Search{search | variables: Poison.encode!(variables)}
  end

  # iex -S mix
  # ElixirGHAnalysis.record_data(["Elixir", "Ruby"])
  # ElixirGHAnalysis.Repo.all(ElixirGHAnalysis.Developer)
  # run source .env in your shell before you run any iex or mix commands.

  def save_developers(%Search{results: results, language: language} = search) do
    case results.body["edges"] do
    nil ->
      IO.puts "No additional repos found..."
    _ ->
      Enum.each results.body["edges"], fn repo ->
        name = repo["node"]["owner"]["name"]
        unless is_nil(name) do
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
    search
  end

  def move_cursor(%Search{results: results} = search) do
    %Search{search | cursor: results.body["pageInfo"]["endCursor"]}
  end

  def add_next_page(%Search{results: results} = search) do
    %Search{search | has_next_page: results.body["pageInfo"]["hasNextPage"]}
  end

  def add_reset_time(%Search{results: results} = search) do
    reset_time = List.keyfind(results.response_headers, "X-RateLimit-Reset", 0)
    |> elem(1)
    |> Integer.parse
    |> elem(0)
    |> DateTime.from_unix |> elem(1)

    %Search{search | reset_time: reset_time}
  end

  def add_remaining_requests(%Search{results: results} = search) do
    requests_remaining = List.keyfind(results.response_headers, "X-RateLimit-Remaining", 0) |> elem(1)

    %Search{search | requests_remaining: requests_remaining}
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
