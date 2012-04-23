module Smailr
    module Alias
        def self.add(address, options)
            mbox_localpart, mbox_fqdn = address.split('@')
            alias_localpart, alias_fqdn = options.alias.split('@')

            # Check if alias_fqdn is a local domain
            if Model::Domain.where(:fqdn => alias_fqdn).empty?
                say_error "You are trying to add an alias for a non-local domain: #{alias_fqdn}"
                exit 1
            end

            # Lookup the mbox object
            mbox = Model::Mailbox[ :localpart => mbox_localpart,
                                   :domain    => Model::Domain.where(:fqdn=> mbox_fqdn) ]
            if not mbox
                say_error "You are trying to add an alias for a non existing mailbox: #{address}"
                exit
            end

            mbox.add_alias(:address => options.alias)
        end

        def self.rm(address, options)
            mbox_localpart, mbox_fqdn = address.split('@')

            # Lookup the mbox object
            mbox = Model::Mailbox[ :localpart => mbox_localpart,
                                   :domain    => Model::Domain.where(:fqdn=> mbox_fqdn) ]

            mbox.remove_alias(Model::Alias[:address => options.alias])
        end

    end
end
