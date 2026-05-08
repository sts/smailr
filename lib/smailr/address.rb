require 'addressable/idna'

module Smailr
  module Address
    # Accepts multi-label ASCII domains up to 253 characters, limits each label
    # to 63 characters, and disallows labels that start or end with a hyphen.
    DOMAIN_PATTERN = /\A(?=.{1,253}\z)(?:(?!-)[a-z0-9-]{1,63}(?<!-)\.)+(?:(?!-)[a-z0-9-]{2,63}(?<!-))\z/i
    LOCALPART_PATTERN = /\A[A-Z0-9._%+\-]+\z/i

    def self.normalize_domain(domain)
      return if domain.nil?

      ascii = Addressable::IDNA.to_ascii(domain.to_s.strip).downcase
      return if ascii.empty? || !ascii.match?(DOMAIN_PATTERN)

      ascii
    rescue StandardError
      nil
    end

    def self.parse_address(address)
      localpart, domain = address.to_s.split('@', 2)
      return if localpart.nil? || domain.nil? || localpart.empty? || domain.empty?
      return unless localpart.match?(LOCALPART_PATTERN)

      normalized_domain = normalize_domain(domain)
      return unless normalized_domain

      [localpart, normalized_domain]
    end

    def self.normalize_address(address)
      localpart, domain = parse_address(address)
      return unless localpart && domain

      "#{localpart}@#{domain}"
    end
  end
end
