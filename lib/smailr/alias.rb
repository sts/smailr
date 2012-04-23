module Smailr
    module Alias
        def self.add(address, options)
            mbox_localpart, mbox_fqdn = address.split('@')
            alias_localpart, alias_fqdn = options.alias.split('@')

            # Check if alias_fqdn is a local domain
            alias_domain = Model::Domain[:fqdn => alias_fqdn]
            if not alias_domain.is_a(Model::Domain)
                error 'You are trying to add an alias for a non-local domain.'
            end
        
            #domain = Model::Domain[:fqdn => fqdn]
            #mbox   = Model::Mailbox.create(:localpart => localpart, :password => password)
            #domain.add_mailbox(mbox)
        end
        
        def self.rm(address, options)
            localpart, fqdn = address.split('@')
        
            mbox   = Model::Mailbox[:localpart => localpart]
            domain = Model::Domain[:fqdn => fqdn]
            domain.remove_mailbox(mbox)
        end
    end
end
