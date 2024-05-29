defmodule GeoLocService.Import do
  alias GeoLocService.GeoLocations
  alias NimbleCSV.RFC4180, as: CSV

  # The fields in order expected in the CSV file.
  @fields [
    :ip_address,
    :country_code,
    :country,
    :city,
    :latitude,
    :longitude,
    :mystery_value
  ]

  @doc """
  Imports the data from the given source into the database.

  The source can be a URL or a local file path.

  The required options are:
  - `:parent_pid` - the parent process ID where messages about each row imported will be sent.
  - `:repo` - the Ecto repo to use for the import.

  The data source is expected to have the following fields including the header row:
  #{@fields |> Enum.join(", ")}

  Sample data:

  ip_address,country_code,country,city,latitude,longitude,mystery_value
  200.106.141.15,SI,Nepal,DuBuquemouth,-84.87503094689836,7.206435933364332,7823011346
  160.103.7.140,CZ,Nicaragua,New Neva,-68.31023296602508,-37.62435199624531,7301823115
  70.95.73.73,TL,Saudi Arabia,Gradymouth,-49.16675918861615,-86.05920084416894,2559997162
  ,PY,Falkland Islands (Malvinas),,75.41685191518815,-144.6943217219469,0
  125.159.20.54,LI,Guyana,Port Karson,-78.2274228596799,-163.26218895343357,1337885276

  """
  @spec run(binary(), Keyword.t()) :: :ok
  def run("http" <> _ = url, opts) do
    remote_stream(url)
    |> process_stream(opts)
  end

  def run(file_path, opts) do
    File.stream!(file_path)
    |> process_stream(opts)
  end

  @spec process_stream(Enumerable.t(), Keyword.t()) :: :ok
  def process_stream(stream, opts) do
    parent_pid = Keyword.fetch!(opts, :parent_pid)
    repo = Keyword.fetch!(opts, :repo)

    stream
    |> CSV.to_line_stream()
    |> CSV.parse_stream()
    |> Stream.with_index()
    |> Task.async_stream(&sanitize_and_create(&1, parent_pid: parent_pid, repo: repo),
      max_concurrency: System.schedulers_online()
    )
    |> Stream.run()

    send(parent_pid, :done)
  end

  @spec sanitize_and_create({[binary()], integer}, Keyword.t()) :: :ok
  def sanitize_and_create(
        {[_, _, _, _, _, _, _] = row, index},
        parent_pid: parent_pid,
        repo: repo
      )
      when is_pid(parent_pid) do
    row
    |> map_to_fields()
    |> GeoLocations.create_geo_location(repo: repo)
    |> case do
      {:ok, _} ->
        send(parent_pid, :accepted)

      {:error, changeset} ->
        send(parent_pid, {:error, changeset, index})
    end
  end

  def sanitize_and_create({row, index}, parent_pid: parent_pid, repo: _repo) do
    send(parent_pid, {:error, "Invalid row data - #{inspect(row)}", index})
  end

  defp map_to_fields(row) do
    Enum.zip(@fields, Enum.map(row, &String.trim/1))
    |> Enum.into(%{})
  end

  defp remote_stream(url) do
    Stream.resource(
      fn -> Req.get!(url, into: :self) end,
      fn resp ->
        # Req function for processing streaming data.
        Req.parse_message(
          resp,
          receive do
            message -> message
          end
        )
        |> case do
          # These are the data chunks.
          {:ok, [data: data]} ->
            {[data], resp}

          # This is returned when the stream is done.
          {:ok, [:done]} ->
            {:halt, resp}

          # This is received inside Finch from a process that is not the socket.
          # Ideally Req should be able to handle this and return a proper error or ignore it.
          :unknown ->
            {[], resp}

          _something_else ->
            {[], resp}
        end
      end,
      fn resp ->
        Req.cancel_async_response(resp)
      end
    )
  end
end
