require 'digest/sha1'

module Smailr
    module Model
        class Domain < Sequel::Model
            one_to_many :mailboxes
            many_to_one :dkim
        end

        class Dkim < Sequel::Model
            many_to_one :domain

            def self.for_domain(fqdn)
                self[:domain => Domain[:fqdn => fqdn]]
            end

            def self.for_domain!(fqdn)
                find_or_create(:domain => Domain[:fqdn => fqdn])
            end
        end

        class Mailbox < Sequel::Model
            many_to_one :domain
            one_to_many :aliases

            def password=(clear)
                self[:password] = Digest::SHA1.hexdigest(clear)
            end

            def self.domain(fqdn)
                Domain[:fqdn => fqdn]
            end

            def self.for_address(address)
                localpart, fqdn = address.split('@')
                self[:localpart => localpart, :domain => domain(fqdn)]
            end

            def self.for_address!(address)
                localpart, fqdn = address.split('@')
                find_or_create(:localpart => localpart, :domain => domain(fqdn))
            end

        end

        class Alias < Sequel::Model
            many_to_one :mailbox
        end
    end
end
