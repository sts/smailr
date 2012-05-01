require 'rubygems'
require 'sqlite3'
require 'sequel'
require 'commander/import'

module Smailr
    autoload :Model,   'smailr/model'
    autoload :Domain,  'smailr/domain'
    autoload :Mailbox, 'smailr/mailbox'
    autoload :Alias,   'smailr/alias'
    autoload :Dkim,    'smailr/dkim'

    class << self;
        attr_accessor :contrib_directory
        attr_accessor :migrations_directory
    end

    VERSION = '0.4.0'
end

Smailr.contrib_directory    ||= File.expand_path('../../contrib', __FILE__)
Smailr.migrations_directory ||= File.expand_path('../../migrations', __FILE__)
