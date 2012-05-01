module Smailr
    module Mailbox
        def self.add(address, password)
            fqdn = address.split('@')[1]

            if not Model::Domain[:fqdn => fqdn]
                say_error "Trying to add a mailbox for a non existing domain: #{fqdn}"
                exit 1
            end

            mbox = Model::Mailbox.for_address!(address)
            mbox.password = password
            mbox.save
        end

        def self.update_password(address, password)
            mbox = Model::Mailbox.for_address(address)
            mbox.password = password
            mbox.save
        end

        def self.rm(address, options)
            mbox = Model::Mailbox.for_address(address)
            mbox.rm_related
            mbox.destroy
        end
    end
end
