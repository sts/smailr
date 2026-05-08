module Smailr
  class Mailbox
    def self.add(address, password)
      address = Smailr::Address.normalize_address(address) || address
      Smailr::logger.warn("Adding mailbox: #{address}")

      _localpart, fqdn = Smailr::Address.parse_address(address) || address.split('@', 2)

      if not Model::Domain[:fqdn => fqdn]
        raise MissingDomain, "Trying to add a mailbox for a non existing domain: #{fqdn}"
      end

      mbox = Model::Mailbox.for_address!(address)
      mbox.password = password
      mbox.save
    end

    def self.update_password(address, password)
      address = Smailr::Address.normalize_address(address) || address
      mbox = Model::Mailbox.for_address(address)
      mbox.password = password
      mbox.save
    end

    def self.rm(address, options)
      address = Smailr::Address.normalize_address(address) || address
      Smailr::logger.warn("Removing mailbox (from database): #{address}")

      mbox = Model::Mailbox.for_address(address)
      mbox.rm_related
      mbox.destroy
    end
  end
end
