defmodule GeoLocService.ImportServerTest do
  use ExUnit.Case, async: false

  alias GeoLocService.ImportServer

  @sample_data ~s"""
  ip_address,country_code,country,city,latitude,longitude,mystery_value
  200.106.141.15,SI,Nepal,DuBuquemouth,-84.87503094689836,7.206435933364332,7823011346
  160.103.7.140,CZ,Nicaragua,New Neva,-68.31023296602508,-37.62435199624531,7301823115
  70.95.73.73,TL,Saudi Arabia,Gradymouth,-49.16675918861615,-86.05920084416894,2559997162
  ,PY,Falkland Islands (Malvinas),,75.41685191518815,-144.6943217219469,0
  125.159.20.54,LI,Guyana,Port Karson,-78.2274228596799,-163.26218895343357,1337885276
  """

  @test_csv_file_path "test/tmp/test1.csv"
  @error_file_path "test/tmp/error.log"

  setup do
    :ok = File.write(@test_csv_file_path, @sample_data)

    on_exit(fn ->
      if File.exists?(@test_csv_file_path) do
        File.rm!(@test_csv_file_path)
      end

      if File.exists?(@error_file_path) do
        File.rm!(@error_file_path)
      end
    end)

    :ok
  end

  describe "start_link" do
    test "starts the server" do
      assert {:ok, _pid} =
               ImportServer.start_link(
                 source: @test_csv_file_path,
                 error_file_path: @error_file_path,
                 repo: GeoLocService.TestRepo
               )
    end

    test "fails if source is missing" do
      assert_raise KeyError, fn ->
        ImportServer.start_link(
          error_file_path: @error_file_path,
          repo: GeoLocService.TestRepo
        )
      end
    end
  end

  describe "import/2" do
    test "imports the data" do
      {:ok, response} =
        ImportServer.import(@test_csv_file_path,
          error_file_path: @error_file_path,
          repo: GeoLocService.TestRepo
        )

      assert is_binary(response)

      assert String.contains?(response, "Accepted: 4")
      assert String.contains?(response, "Rejected: 1")
    end
  end
end
