require 'date'
require 'openssl'

module Smailr
    module Dkim
        def self.add(fqdn, options)
            options.testing ||= true

            if not Model::Domain[:fqdn => fqdn]
                say_error "You trying to add a DKIM key for a non existing domain: #{fqdn}"
                exit 1
            end

            private_key, public_key = generate_rsa_key
            dkim = Model::Dkim.for_domain!(fqdn)
            dkim.set(:private_key => private_key,
                     :public_key  => public_key,
                     :testing     => options.testing)
            dkim.save
        end

        def self.rm(fqdn, options)
            dkim = Model::Dkim.for_domain(fqdn)
            dkim.destroy
        end

        private

            def self.generate_rsa_key(length = 1024)
                rsa_key     = OpenSSL::PKey::RSA.new(length)
                [ rsa_key.to_pem,
                  rsa_key.public_key.to_pem ]
            end
    end
end
