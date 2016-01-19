require 'rubygems'
require 'yaml'
require 'sqlite3'
require 'sequel'
require 'commander/import'
require 'fileutils'

module Smailr
    VERSION = '0.6.0'

    autoload :Model,   'smailr/model'
    autoload :Domain,  'smailr/domain'
    autoload :Mailbox, 'smailr/mailbox'
    autoload :Alias,   'smailr/alias'
    autoload :Dkim,    'smailr/dkim'
    autoload :Setup,   'smailr/setup'

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


end

Smailr.contrib_directory    ||=   File.expand_path('../../contrib', __FILE__)
Smailr.migrations_directory ||=   File.expand_path('../../migrations', __FILE__)
Smailr.config_files         ||=  [ File.expand_path('../../smailr.yml', __FILE__),  '/etc/smailr.yml']
Smailr.load_config
Smailr::DB = Smailr::db_connect
