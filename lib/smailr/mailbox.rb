module Smailr
  class Mailbox
    def self.add(address, password)
      Smailr::logger.warn("Adding mailbox: #{address}")

      fqdn = address.split('@')[1]

      if not Model::Domain[:fqdn => fqdn]
        raise MissingDomain, "Trying to add a mailbox for a non existing domain: #{fqdn}"
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
      Smailr::logger.warn("Removing mailbox (from database): #{address}")

      mbox = Model::Mailbox.for_address(address)
      mbox.rm_related
      mbox.destroy
    end
  end
end
