require 'rubygems'
require 'yaml'
require 'sqlite3'
require 'sequel'
require 'commander/import'
require 'fileutils'

module Smailr
    VERSION = '0.5.0'

    autoload :Model,   'smailr/model'
    autoload :Domain,  'smailr/domain'
    autoload :Mailbox, 'smailr/mailbox'
    autoload :Alias,   'smailr/alias'
    autoload :Dkim,    'smailr/dkim'

    class << self;
        attr_accessor :config
        attr_accessor :load_config
        attr_accessor :contrib_directory
        attr_accessor :migrations_directory
    end

    def self.load_config=(files)
        config = {}
        files.each do |f|
            if File.readable?(f)
                config.merge!(YAML.load_file(f))
            end
        end
        self.config = config
    end

    def self.db_connect
        Sequel.connect(self.config['database'])
    end


    def self.setup
        prefix = self.contrib_directory

        FileUtils.mkdir_p "smailr-etc/exim4"
        FileUtils.mkdir_p "smailr-etc/dovecot"

        FileUtils.cp File.expand_path("../README.md", prefix),    "smailr-etc/"
        FileUtils.cp File.expand_path("../smailr.yml", prefix),   "smailr-etc/"
        FileUtils.cp File.expand_path("exim4.conf", prefix),      "smailr-etc/exim4"
        FileUtils.cp File.expand_path("dovecot.conf", prefix),    "smailr-etc/dovecot"
        FileUtils.cp File.expand_path("dovecot-sql.conf", prefix),"smailr-etc/dovecot"

        say "*****************************************************************"
        say "All needed configuration files are in ./smailr-etc for review."
        say "\n"
        say "Please install exim4, dovecot and then run the commands below, or"
        say "adjust the file locations according to your environment."
        say "\n"
        say "Also make sure to configure a location for the SQLite database"
        say "file in smailr.yml."
        say "\n"
        say "Then run 'smailr migrate' to initialize the database."
        say "*****************************************************************"
        say "\n"
        say "cp smailr-etc/smailr.yml /etc/smailr.yml"
        say "cp smailr-etc/dovecot.conf /etc/dovecot/"
        say "cp smailr-etc/dovecot-sql.conf /etc/dovecot/"
        say "cp smailr-etc/exim4/"

        # Future version could maybe launch puppet here?
        #
        #instalpp = File.expand_path('/install.pp', self.contrib_directory)
        #if agree("Shall we launch puppet with the manifest from #{installpp}? (yes/no) ")
        #    exec "puppet apply #{installpp}"
        #end
    end
end

Smailr.contrib_directory    ||=   File.expand_path('../../contrib', __FILE__)
Smailr.migrations_directory ||=   File.expand_path('../../migrations', __FILE__)
Smailr.load_config          ||= [ File.expand_path('../../smailr.yml', __FILE__),  '/etc/smailr.yml' ]
Smailr::DB = Smailr::db_connect
