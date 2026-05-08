require_relative "test_helper"

class SmailrAddressTest < Minitest::Test
  def test_normalize_domain_accepts_idn_and_long_tld
    assert_equal "xn--bcher-kva.ch", Smailr::Address.normalize_domain("bücher.ch")
    assert_equal "example.technology", Smailr::Address.normalize_domain("example.technology")
  end

  def test_normalize_address_converts_idn_domain
    assert_equal "user@xn--bcher-kva.ch", Smailr::Address.normalize_address("user@bücher.ch")
  end

  def test_normalize_address_rejects_invalid_addresses
    assert_nil Smailr::Address.normalize_address("missing-at-sign")
    assert_nil Smailr::Address.normalize_address("user@@example.com")
    assert_nil Smailr::Address.normalize_address("@example.com")
    assert_nil Smailr::Address.normalize_address("user@")
    assert_nil Smailr::Address.normalize_address("us er@example.com")
  end

  def test_normalize_domain_rejects_invalid_domain
    assert_nil Smailr::Address.normalize_domain("not a domain")
    assert_nil Smailr::Address.normalize_domain("")
    assert_nil Smailr::Address.normalize_domain("exa_mple.com")
    assert_nil Smailr::Address.normalize_domain("#{"a" * 64}.com")
    assert_nil Smailr::Address.normalize_domain("#{'a.' * 127}aa")
  end
end

class SmailrDomainNormalizationTest < Minitest::Test
  def setup
    @original_model = Smailr.const_get(:Model) if Smailr.const_defined?(:Model, false)
    Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)

    model = Module.new
    model.const_set(:Domain, Class.new)
    model.const_set(:Mailbox, Class.new)
    model.const_set(:Alias, Class.new)
    Smailr.const_set(:Model, model)
  end

  def teardown
    Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)
    Smailr.const_set(:Model, @original_model) if @original_model
  end

  def test_domain_add_normalizes_idn
    calls = []

    Smailr::Model::Domain.define_singleton_method(:create) do |attributes|
      calls << attributes
    end

    Smailr::Domain.add("bücher.ch")

    assert_equal [{ fqdn: "xn--bcher-kva.ch" }], calls
  end

  def test_mailbox_add_normalizes_idn_domain
    lookups = []
    addresses = []
    domain = Object.new
    mailbox = Object.new

    Smailr::Model::Domain.define_singleton_method(:[]) do |criteria|
      lookups << criteria
      domain
    end
    mailbox.define_singleton_method(:password=) { |_password| }
    mailbox.define_singleton_method(:save) { true }
    Smailr::Model::Mailbox.define_singleton_method(:for_address!) do |address|
      addresses << address
      mailbox
    end

    Smailr::Mailbox.add("user@bücher.ch", "secret")

    assert_equal [{ fqdn: "xn--bcher-kva.ch" }], lookups
    assert_equal ["user@xn--bcher-kva.ch"], addresses
  end

  def test_alias_add_normalizes_idn_domains
    domain = Object.new
    calls = []

    Smailr::Model::Domain.define_singleton_method(:[]) do |_criteria|
      domain
    end
    Smailr::Model::Alias.define_singleton_method(:find_or_create) do |attributes|
      calls << attributes
    end

    Smailr::Alias.add("info@bücher.ch", ["user@bücher.ch"])

    assert_equal [
      {
        domain: domain,
        localpart: "info",
        dstdomain: "xn--bcher-kva.ch",
        dstlocalpart: "user"
      }
    ], calls
  end
end
