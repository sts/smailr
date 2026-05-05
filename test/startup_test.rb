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
end
