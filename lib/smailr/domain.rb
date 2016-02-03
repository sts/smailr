module Smailr
  class Domain
    def self.add(fqdn)
      Smailr::logger.warn("Adding domain: #{fqdn}")
      Model::Domain.create(:fqdn => fqdn)
    end

    def self.rm(fqdn, force = false)
      # TODO - only require force, if related entries exist
      if force
        domain = Model::Domain[:fqdn => fqdn]
        domain.rm_related
        domain.destroy
      end
    end
  end
end
