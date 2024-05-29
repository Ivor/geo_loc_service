defmodule GeoLocService.ConfigTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      Application.put_env(:geo_loc_service, :repo, nil)
      Application.put_env(:geo_loc_service, :error_file_path, nil)
    end)
  end

  describe "repo!" do
    test "raises if the config is needed but missing" do
      assert_raise RuntimeError, fn ->
        GeoLocService.Config.repo!()
      end
    end

    test "returns the configured value if it exists" do
      Application.put_env(:geo_loc_service, :repo, GeoLocService.TestRepo)
      assert GeoLocService.TestRepo = GeoLocService.Config.repo!()
    end
  end

  describe "error_file_path!" do
    test "raises if the config is needed but missing" do
      assert_raise RuntimeError, fn ->
        GeoLocService.Config.error_file_path!()
      end
    end

    test "returns the configured value if it exists" do
      Application.put_env(:geo_loc_service, :error_file_path, "error.log")
      assert "error.log" == GeoLocService.Config.error_file_path!()
    end
  end
end
