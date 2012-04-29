module Smailr
    module Mailbox
        def self.add(address, options)
            fqdn = address.split('@')[1]

            if not Model::Domain[:fqdn => fqdn]
                say_error "You trying to add a mailbox for a non existing domain: #{fqdn}"
                exit 1
            end

            if options.password
                password = options.password
            else
                password = ask_password
            end

            mbox = Model::Mailbox.for_address!(address)
            mbox.set(:password => password)
            mbox.save
        end

        def self.rm(address, options)
            mbox = Model::Mailbox.for_address(address)

            # We don't want to end up with an inconsistent database here.
            if not mbox.aliases.empty?
                say_error "Trying to remove a mailbox, with existing aliases."
                exit 1
            end

            mbox.destroy
        end

        private

            def self.ask_password
                 min_password_length = 5
                 password = ask("Password: ") { |q| q.echo = "*" }
                 confirm  = ask("Confirm: ")  { |q| q.echo = "*" }

                if password != confirm
                    say("Mismatch; try again.")
                    ask_password
                end

                if password.length < min_password_length
                    say("Too short; try again.")
                    ask_password
                end

                return password
            end
    end
end
