defmodule GeoLocService.ImportServer do
  @moduledoc """
  The ImportServer GenServer.

  Start with a source, error file path, and repo. The source is the path to the file or url to import.

  The server starts a task to do the import then waits to receive messages from the task for each row processed.

  When the import is done a :done message is received which closes the error log file and prints the import stats.
  """

  use GenServer

  alias GeoLocService.Import
  alias GeoLocService.ErrorHelpers
  alias GeoLocService.ImportServer.State

  defmodule State do
    @moduledoc """
    The state of the ImportServer GenServer.

    ## Attributes

    * `error_file_path` - the path to the error log file
    * `error_log_file` - the file reference for the error log file
    * `start_time` - the time the import started
    * `source` - the source of the import
    * `repo` - the Ecto repo
    * `accepted` - the number of accepted rows
    * `rejected` - the number of rejected rows
    """

    defstruct [
      :error_file_path,
      :error_log_file,
      :start_time,
      :source,
      :repo,
      accepted: 0,
      rejected: 0
    ]
  end

  def start_link(opts) do
    source = Keyword.fetch!(opts, :source)

    GenServer.start_link(__MODULE__, opts, name: via_tuple(source))
  end

  @impl true
  def init(opts) do
    source = Keyword.fetch!(opts, :source)
    error_file_path = Keyword.fetch!(opts, :error_file_path)
    repo = Keyword.fetch!(opts, :repo)

    start_time = System.monotonic_time()

    {:ok, error_file} = File.open(error_file_path, [:write, :utf8])

    state = %State{
      error_file_path: error_file_path,
      error_log_file: error_file,
      start_time: start_time,
      source: source,
      repo: repo
    }

    {:ok, state, {:continue, :import}}
  end

  @impl true
  def handle_continue(:import, state) do
    server_pid = self()

    Task.async(Import, :run, [state.source, [parent_pid: server_pid, repo: state.repo]])

    {:noreply, state}
  end

  @impl true
  def handle_info({:error, changeset_or_reason, index}, state) do
    state.error_log_file
    |> write_to_file(changeset_or_reason, index)

    {:noreply, update_count(state, :rejected)}
  end

  @impl true
  def handle_info(:accepted, state) do
    {:noreply, update_count(state, :accepted)}
  end

  @impl true
  def handle_info(:done, state) do
    File.close(state.error_log_file)

    print_state(state)

    {:stop, :normal, state}
  end

  defp write_to_file(file, changeset_or_message, index) do
    message =
      case changeset_or_message do
        %Ecto.Changeset{} = changeset -> ErrorHelpers.full_error_string(changeset)
        message when is_binary(message) -> message
      end

    IO.write(file, [
      "Row #{index} is invalid: ",
      message,
      "\n"
    ])
  end

  defp update_count(state, key) when key in [:accepted, :rejected] do
    Map.update!(state, key, &(&1 + 1))
  end

  def print_state(state) do
    IO.puts(~s"""
    Elapsed time: #{System.monotonic_time() - state.start_time} ms
    Accepted: #{state.accepted}
    Rejected: #{state.rejected} (#{state.rejected / (state.accepted + state.rejected) * 100}% of total)
    Total: #{state.accepted + state.rejected}

    Errors written to: #{state.error_file_path}
    """)
  end

  def via_tuple(source) do
    {:via, Registry, {GeoLocService.Registry, {__MODULE__, source}}}
  end
end
