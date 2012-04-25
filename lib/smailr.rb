require 'rubygems'
require 'sqlite3'
require 'sequel'
require 'commander/import'

module Smailr
    autoload :Model,   'smailr/model'
    autoload :Domain,  'smailr/domain'
    autoload :Mailbox, 'smailr/mailbox'
    autoload :Alias,   'smailr/alias'

    program :version, '0.2.0'
    program :description, 'Simple MAIL mangaR - Virtual mail hosting management from the CLI'
end
