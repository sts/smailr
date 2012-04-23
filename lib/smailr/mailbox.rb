module Smailr
    module Mailbox
        def self.add(address, options)
            if not options.password?
                begin
                    password  = ask("Password: ") { |q| q.echo = "*" }
                    password1 = ask("Confirm:  ") { |q| q.echo = "*" }
                    say "Mismatch; try again." if password != password1
                end while password != password1
            else
                password = options[:password]
            end
        
            localpart, fqdn = address.split('@')
        
            domain = Model::Domain[:fqdn => fqdn]
            mbox   = Model::Mailbox.create(:localpart => localpart, :password => password)
            domain.add_mailbox(mbox)
        end
        
        def self.rm(address, options)
            localpart, fqdn = address.split('@')
        
            mbox   = Model::Mailbox[:localpart => localpart]
            domain = Model::Domain[:fqdn => fqdn]
            domain.remove_mailbox(mbox)
        end
    end
end
