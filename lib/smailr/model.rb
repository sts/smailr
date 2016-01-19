require 'digest/sha1'

module Smailr
    module Model
        class Domain < Sequel::Model
            one_to_many :mailboxes
            one_to_many :aliases
            one_to_many :dkims

            def rm_related
                self.remove_all_mailboxes
                self.remove_all_aliases
                self.remove_all_dkims
            end
        end

        class Dkim < Sequel::Model
            many_to_one :domain

            def self.for_domain(fqdn, selector)
                self[:domain => Domain[:fqdn => fqdn], :selector => selector]
            end

            def self.for_domain!(fqdn, selector)
                find_or_create(:domain => Domain[:fqdn => fqdn], :selector => selector)
            end
         end

        class Mailbox < Sequel::Model
            many_to_one :domain

            def password=(clear)
                self[:password] = Digest::SHA1.hexdigest(clear)
                self[:password_scheme] = "{SHA}"
            end

            def rm_related
                self.aliases.destroy
            end

            def aliases
                Model::Alias.where(
                    :dstlocalpart => self.localpart,
                    :dstdomain   => self.domain.fqdn
                )
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
            many_to_one :domain
        end
    end
end
