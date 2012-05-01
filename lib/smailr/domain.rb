module Smailr
    module Domain
        def self.add(fqdn)
            puts "Adding domain: #{fqdn}"
            Model::Domain.create(:fqdn => fqdn)
        end

        def self.rm(fqdn, force = false)
            if force or
                agree("Do you want to remove the domain #{fqdn} and all related items? (yes/no) ")

                domain = Model::Domain[:fqdn => fqdn]
                domain.rm_related
                domain.destroy
            end
        end
    end
end
