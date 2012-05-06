require 'rubygems'
require 'yaml'
require 'sqlite3'
require 'sequel'
require 'commander/import'
require 'fileutils'

module Smailr
    VERSION = '0.5.2'

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

        if not File.exists?("/etc/smailr.yml")
            if not File.writable?("/etc")
               say_error "Cannot copy configuration to /etc/smailr.yml - permission denied."
               exit 1
            end
            FileUtils.cp File.expand_path("../smailr.yml", prefix), "/etc/smailr.yml"
            say "Configuration installed in /etc/smailr.yml. Please revise, then run 'smailr setup' again."
        else
            # ALWAYS WARN HERE
            if not agree("**** WARNING ****   Script will overwrite Exim and Dovecot configuration files in /etc? (yes/no) ")
                say "**** ABORTED ****   You can find all example configs in: #{prefix}"
                exit 1
            end

            # Only install configuration if needed
            if config["exim_path"]
                if File.writable?(config["exim_path"])
                    FileUtils.cp File.expand_path("exim4.conf", prefix), config["exim_path"]
                else
                    say_error "Cannot copy Exim configuration to #{config["exim_path"]} - permission denied or path doesn't exist."
                    exit 1
                end
            end

            if config["dovecot_path"]
                if File.writable?(config["dovecot_path"])
                    FileUtils.cp File.expand_path("dovecot.conf", prefix),     config["dovecot_path"]
                    FileUtils.cp File.expand_path("dovecot-sql.conf", prefix), config["dovecot_path"]
                else
                    say_error "Cannot copy Dovecot configuration to #{config["dovecot_path"]} - permission denied or path doesn't exist."
                    exit 1
                end
            end

            if config["mail_spool_path"]
                exec "useradd -r -d #{config["mail_spool_path"]} vmail"
                FileUtils.mkdir_p "#{config["mail_spool_path"]}/users"
                FileUtils.chown "vmail", "vmail", config["mail_spool_path"]
            end
        end
    end
end

Smailr.contrib_directory    ||=   File.expand_path('../../contrib', __FILE__)
Smailr.migrations_directory ||=   File.expand_path('../../migrations', __FILE__)
Smailr.load_config          ||= [ File.expand_path('../../smailr.yml', __FILE__),  '/etc/smailr.yml' ]
Smailr::DB = Smailr::db_connect
