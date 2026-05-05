require_relative "test_helper"

class SmailrStartupTest < Minitest::Test
  def setup
    @config = Smailr.config
    @config_files = Smailr.config_files
    @bundled_config_file = Smailr.bundled_config_file
  end

  def teardown
    Smailr.config = @config
    Smailr.config_files = @config_files
    Smailr.bundled_config_file = @bundled_config_file
  end

  def test_load_config_reports_missing_runtime_config
    Dir.mktmpdir do |dir|
      bundled = File.join(dir, "bundled.yml")
      missing = File.join(dir, "smailr.yml")

      File.write(bundled, "---\ndatabase:\n  adapter: sqlite\n  database: bundled.sqlite3\n")

      Smailr.bundled_config_file = bundled
      Smailr.config_files = [bundled, missing]

      error = assert_raises(Smailr::ConfigurationError) do
        Smailr.load_config
      end

      assert_equal "Cannot find configuration file. Checked: #{missing}", error.message
    end
  end

  def test_load_config_reports_unreadable_runtime_config
    Dir.mktmpdir do |dir|
      bundled = File.join(dir, "bundled.yml")
      unreadable = File.join(dir, "smailr.yml")

      File.write(bundled, "---\ndatabase:\n  adapter: sqlite\n  database: bundled.sqlite3\n")
      File.write(unreadable, "---\n")

      Smailr.bundled_config_file = bundled
      Smailr.config_files = [bundled, unreadable]

      File.stub(:readable?, ->(path) { path == unreadable ? false : FileTest.readable?(path) }) do
        error = assert_raises(Smailr::ConfigurationError) do
          Smailr.load_config
        end

        assert_equal "Cannot read configuration file: #{unreadable}", error.message
      end
    end
  end

  def test_db_connect_reports_missing_database_settings
    Smailr.config = {}

    error = assert_raises(Smailr::ConfigurationError) do
      Smailr.db_connect
    end

    assert_equal "Configuration file is missing database settings.", error.message
  end

  def test_initialize_sets_database_before_loading_models
    database = Object.new
    database.define_singleton_method(:sql_log_level=) { |_level| }
    previous_model = Sequel::Model.instance_variable_get(:@db)
    loaded_model = false

    Smailr.config_files = ["/tmp/missing.yml", "/tmp/runtime.yml"]

    Smailr.stub(:load_config, { "database" => { "adapter" => "sqlite", "database" => "test.sqlite3" } }) do
      Smailr.stub(:db_connect, database) do
        Smailr.stub(:require, ->(feature) {
          if feature == "smailr/model"
            loaded_model = true
            assert_same database, Smailr::DB
            assert_same database, Sequel::Model.db
          end
          true
        }) do
          Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)
          Smailr.initialize!
        end
      end
    end

    assert loaded_model
  ensure
    Sequel::Model.db = previous_model if previous_model
    Smailr.send(:remove_const, :DB) if Smailr.const_defined?(:DB, false)
    Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)
  end

  def test_bin_version_works_without_configuration
    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby,
      "-Ilib",
      File.expand_path("../bin/smailr", __dir__),
      "--version"
    )

    assert status.success?
    assert_equal "smailr #{Smailr::VERSION}\n", stdout
    refute_includes stderr, "ERROR:"
    refute_includes stderr, "Cannot find configuration file"
  end

  def test_bin_version_command_works_without_configuration
    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby,
      "-Ilib",
      File.expand_path("../bin/smailr", __dir__),
      "version"
    )

    assert status.success?
    assert_equal "smailr #{Smailr::VERSION}\n", stdout
    refute_includes stderr, "ERROR:"
    refute_includes stderr, "Cannot find configuration file"
  end
end
