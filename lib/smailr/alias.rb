module Smailr
    module Alias
        def self.add(address, options)
            mbox_localpart, mbox_fqdn = address.split('@')
            alias_localpart, alias_fqdn = options.alias.split('@')

            # We don't want aliases for non-local domains, since the
            # exim router won't accept it.
            if not Model::Alias.domain(alias_fqdn).exists?
                say_error "You are trying to add an alias for a non-local domain: #{alias_fqdn}"
                exit 1
            end

            mbox = Model::Alias.mbox_for_address(address)

            # We don't want aliases which cannot be routed to a mailbox.
            if not mbox.exists?
                say_error "You are trying to add an alias for a non existing mailbox: #{address}"
                exit 1
            end

            mbox.add_alias(:address => options.alias)
        end

        def self.rm(address, options)
            mbox = Model::Alias.mbox_for_address(address)
            mbox.remove_alias(Model::Alias[:address => options.alias])
        end
    end
end
