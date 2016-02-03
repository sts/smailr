module Smailr
  class Dkim
    def self.add(fqdn, selector)
      unless Model::Domain[:fqdn => fqdn]
        raise MissingDomain, "You trying to add a DKIM key for a non existing domain: #{fqdn}"
      end

      private_key, public_key = generate_rsa_key

      dkim = Model::Dkim.for_domain!(fqdn, selector)
      dkim.private_key = private_key
      dkim.public_key  = public_key
      dkim.selector    = selector
      dkim.save

      # Return the key so it can be used for automation
      dkim.public_key
    end

    def self.rm(fqdn, selector)
      dkim = Model::Dkim.for_domain(fqdn, selector)
      dkim.destroy
    end

    private

    def self.generate_rsa_key(length = 1024)
      rsa_key = OpenSSL::PKey::RSA.new(length)
      [ rsa_key.to_pem,
        rsa_key.public_key.to_pem ]
    end
  end
end
