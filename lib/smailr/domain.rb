module Smailr
    module Domain
        def self.add(fqdn)
            puts "Adding domain: #{fqdn}"
            domain = Model::Domain.create(:fqdn => fqdn)
        end
        
        def self.rm(fqdn, options)
            if options.force or
               agree("**** Remove domain #{fqdn} and all its mailboxes? ")
                domain = Model::Domain[:fqdn => fqdn]
                domain.mailboxes_dataset.destroy
                domain.destroy
            end
        end
        
    end
end
