module Smailr
  class Alias
    def self.add(source, destinations)
      srclocalpart, srcdomain = Smailr::Address.parse_address(source) || source.split('@', 2)
      domain = Model::Domain[:fqdn => srcdomain]

      # We don't want aliases for non-local domains, since the
      # exim router won't accept it.
      unless domain
        raise MissingDomain, "You are trying to add an alias for a non existing domain: #{source}"
      end

      destinations.each do |dst|
        dstlocalpart, dstdomain = Smailr::Address.parse_address(dst) || dst.split('@', 2)

        Smailr::logger.warn("Adding alias: #{source} -> #{dst}")

        Model::Alias.find_or_create(:domain       => domain,
                                    :localpart    => srclocalpart,
                                    :dstdomain    => dstdomain,
                                    :dstlocalpart => dstlocalpart)
      end
    end

    def self.rm(source, destinations)
      srclocalpart, srcdomain = Smailr::Address.parse_address(source) || source.split('@', 2)

      destinations.each do |dst|
        Smailr::logger.warn("Removing alias: #{source} -> #{dst}")

        dstlocalpart, dstdomain = Smailr::Address.parse_address(dst) || dst.split('@', 2)

        Model::Alias.filter(:domain       => Model::Domain[:fqdn => srcdomain],
                            :localpart    => srclocalpart,
                            :dstdomain    => dstdomain,
                            :dstlocalpart => dstlocalpart).delete
      end
    end
  end
end
