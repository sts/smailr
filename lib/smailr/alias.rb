module Smailr
    module Alias
        def self.add(address, options)
            mbox_localpart, mbox_fqdn = address.split('@')
            alias_localpart, alias_fqdn = options.alias.split('@')

            # Check if alias_fqdn is a local domain
            if Model::Domain.where(:fqdn => alias_fqdn).empty?
                say_error "You are trying to add an alias for a non-local domain: #{alias_fqdn}"
            end

            mbox = Model::Mailbox[:localpart => mbox_localpart, :domain => mbox_fqdn]
            mbox.add_alias(:address => options.alias)
        end
    end
end
