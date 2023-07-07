require 'rubygems'

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

  VERSION = '0.8.0'

  class << self;
    attr_accessor :config
    attr_accessor :config_files
    attr_accessor :load_config
    attr_accessor :contrib_directory
    attr_accessor :migrations_directory
  end

  def self.load_config
    config = {}
    config_files.each do |f|
      if File.readable?(f)
        config.merge!(YAML.load_file(f))
      end
    end
    self.config = config
  end

  def self.db_connect
    Sequel.connect(self.config['database'])
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
Smailr.config_files         ||= [ File.expand_path('../../smailr.yml', __FILE__),  '/etc/smailr.yml']
Smailr.load_config
Smailr::DB = Smailr::db_connect
require 'smailr/model'
Smailr::DB.sql_log_level = :debug
