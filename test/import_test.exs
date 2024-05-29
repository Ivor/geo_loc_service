defmodule GeoLocService.ImportTest do
  use ExUnit.Case, async: false

  import Plug.Conn

  alias GeoLocService.Import
  alias GeoLocService.TestRepo

  @sample_data ~s"""
  ip_address,country_code,country,city,latitude,longitude,mystery_value
  200.106.141.15,SI,Nepal,DuBuquemouth,-84.87503094689836,7.206435933364332,7823011346
  160.103.7.140,CZ,Nicaragua,New Neva,-68.31023296602508,-37.62435199624531,7301823115
  70.95.73.73,TL,Saudi Arabia,Gradymouth,-49.16675918861615,-86.05920084416894,2559997162
  ,PY,Falkland Islands (Malvinas),,75.41685191518815,-144.6943217219469,0
  125.159.20.54,LI,Guyana,Port Karson,-78.2274228596799,-163.26218895343357,1337885276
  """

  @test_csv_file_path "test/tmp/test.csv"

  setup do
    on_exit(fn ->
      if File.exists?(@test_csv_file_path) do
        File.rm!(@test_csv_file_path)
      end
    end)
  end

  describe "run" do
    test "runs with a URL" do
      # In this test we create a HTTP mock server using Bypass.
      # We take the same sample data and return it chuncked.
      bypass = Bypass.open()

      Bypass.expect_once(bypass, fn conn ->
        conn =
          conn
          |> put_resp_content_type("application/csv")
          |> put_resp_header("content-disposition", "attachment; filename=download.csv")
          |> put_resp_header("transfer-encoding", "chunked")
          |> send_chunked(200)

        with {:ok, pid} = StringIO.open(@sample_data) do
          IO.binstream(pid, 100)
          |> Enum.reduce(conn, fn chunk, conn ->
            {:ok, conn} = chunk(conn, chunk)

            conn
          end)
        end

        {:ok, conn} = Plug.Conn.chunk(conn, "")
        conn
      end)

      Import.run("http://localhost:#{bypass.port()}",
        parent_pid: self(),
        repo: TestRepo
      )

      assert_messages()
    end

    test "runs with a file path" do
      :ok = File.write(@test_csv_file_path, @sample_data)
      :done = Import.run(@test_csv_file_path, parent_pid: self(), repo: TestRepo)

      assert_messages()
    end
  end

  describe "sanitize_and_create" do
    test "accepts a geo location with valid data" do
      row = @sample_data |> String.split("\n") |> Enum.at(1) |> String.split(",")
      parent_pid = self()
      repo = TestRepo

      assert :accepted = Import.sanitize_and_create({row, 1}, parent_pid: parent_pid, repo: repo)
    end

    test "rejects a geo location with invalid data" do
      row = @sample_data |> String.split("\n") |> Enum.at(4) |> String.split(",")
      parent_pid = self()
      repo = TestRepo

      assert {:error, _, _} =
               Import.sanitize_and_create({row, 4}, parent_pid: parent_pid, repo: repo)
    end

    test "returns an error message with an invalid row" do
      row = @sample_data |> String.split("\n") |> Enum.at(1) |> String.split(",") |> Enum.take(3)
      parent_pid = self()
      repo = TestRepo

      expected_message = "Invalid row data - #{inspect(row)}"

      assert {:error, ^expected_message, 10} =
               Import.sanitize_and_create({row, 10}, parent_pid: parent_pid, repo: repo)
    end
  end

  defp assert_messages() do
    messages =
      Enum.reduce_while(0..5, [], fn _, acc ->
        receive do
          :done -> {:halt, acc}
          :accepted = message -> {:cont, [message | acc]}
          {:error, _, _} = message -> {:cont, [message | acc]}
        after
          1000 ->
            IO.puts("Timeout waiting for message.")
            {:halt, acc}
        end
      end)

    assert Enum.count(messages, fn
             :accepted -> true
             _ -> false
           end) == 4

    assert Enum.count(messages, fn
             {:error, _, _} -> true
             _ -> false
           end) == 1
  end
end
