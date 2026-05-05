require 'rubygems'
require 'smailr/version'

require 'fileutils'
require 'logger'
require 'sequel'
require 'sqlite3'
require 'yaml'

# dkim
require 'date'
require 'openssl'

require 'smailr/alias'
require 'smailr/dkim'
require 'smailr/domain'
require 'smailr/mailbox'

module Smailr

  # Exception Classes
  class MissingDomain < StandardError ; end
  class ConfigurationError < StandardError ; end

  class << self;
    attr_accessor :config
    attr_accessor :config_files
    attr_accessor :contrib_directory
    attr_accessor :migrations_directory
    attr_accessor :bundled_config_file
  end

  def self.load_config
    config = {}
    runtime_config_files = config_files.reject { |f| f == bundled_config_file }
    readable_runtime_config_files = runtime_config_files.select { |f| File.file?(f) && File.readable?(f) }
    unreadable_runtime_config_files = runtime_config_files.select { |f| File.exist?(f) && !File.readable?(f) }

    if readable_runtime_config_files.empty?
      if unreadable_runtime_config_files.any?
        raise ConfigurationError, "Cannot read configuration file: #{unreadable_runtime_config_files.join(', ')}"
      end

      raise ConfigurationError, "Cannot find configuration file. Checked: #{runtime_config_files.join(', ')}"
    end

    if bundled_config_file && File.readable?(bundled_config_file)
      config.merge!(YAML.load_file(bundled_config_file) || {})
    end

    readable_runtime_config_files.each do |f|
      config.merge!(YAML.load_file(f) || {})
    end

    self.config = config
  end

  def self.db_connect
    unless self.config && self.config['database']
      raise ConfigurationError, "Configuration file is missing database settings."
    end

    Sequel.connect(self.config['database'])
  rescue Sequel::DatabaseConnectionError => e
    raise ConfigurationError, "Cannot open database connection: #{e.message}"
  end

  def self.initialize!
    load_config
    database = db_connect

    Smailr.send(:remove_const, :DB) if Smailr.const_defined?(:DB, false)
    Smailr.const_set(:DB, database)
    Sequel::Model.db = database

    unless defined?(Smailr::Model)
      require 'smailr/model'
    end

    Smailr::DB.sql_log_level = :debug
  end

  def self.logger
    unless @logger
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::Severity::DEBUG
      @logger.formatter = proc do |severity, datetime, progname, msg|
        if severity == "ERROR"
            "ERROR: #{msg}\n"
        else
            "#{msg}\n"
        end
      end
    end
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end
end

Smailr.contrib_directory    ||= File.expand_path('../../contrib', __FILE__)
Smailr.migrations_directory ||= File.expand_path('../../migrations', __FILE__)
Smailr.bundled_config_file  ||= File.expand_path('../../smailr.yml', __FILE__)
Smailr.config_files         ||= [ Smailr.bundled_config_file, '/etc/smailr.yml' ]
