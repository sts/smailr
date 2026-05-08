require_relative "test_helper"

class SmailrDkimTest < Minitest::Test
  def setup
    @original_model = Smailr.const_get(:Model) if Smailr.const_defined?(:Model, false)
    Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)

    model = Module.new
    model.const_set(:Domain, Class.new)
    model.const_set(:Dkim, Class.new)
    Smailr.const_set(:Model, model)

    @original_logger = Smailr.instance_variable_get(:@logger)
    Smailr.logger = Logger.new(File::NULL)
  end

  def teardown
    Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)
    Smailr.const_set(:Model, @original_model) if @original_model
    Smailr.instance_variable_set(:@logger, @original_logger)
  end

  def test_add_raises_missing_domain_when_domain_not_found
    Smailr::Model::Domain.define_singleton_method(:[]) { |_| nil }

    error = assert_raises(Smailr::MissingDomain) do
      Smailr::Dkim.add("example.com", "mx")
    end

    assert_includes error.message, "example.com"
  end

  def test_add_generates_rsa_key_and_saves_dkim_record
    domain = Object.new
    private_key_set = nil
    public_key_set  = nil
    selector_set    = nil
    saved           = false
    public_key_value = "-----BEGIN PUBLIC KEY-----\nMIIB\n-----END PUBLIC KEY-----\n"

    dkim = Object.new
    dkim.define_singleton_method(:private_key=) { |v| private_key_set = v }
    dkim.define_singleton_method(:public_key=)  { |v| public_key_set  = v }
    dkim.define_singleton_method(:selector=)    { |v| selector_set    = v }
    dkim.define_singleton_method(:save)         { saved = true }
    dkim.define_singleton_method(:public_key)   { public_key_value }

    Smailr::Model::Domain.define_singleton_method(:[]) { |_| domain }
    Smailr::Model::Dkim.define_singleton_method(:for_domain!) { |_fqdn, _sel| dkim }

    result = Smailr::Dkim.add("example.com", "mx")

    assert_equal "mx", selector_set
    refute_nil private_key_set, "expected private_key to be set"
    refute_nil public_key_set,  "expected public_key to be set"
    assert saved, "expected save to be called"
    assert_equal public_key_value, result
  end

  def test_add_passes_fqdn_and_selector_to_for_domain_bang
    domain = Object.new
    for_domain_args = []
    saved_key = "pub"

    dkim = Object.new
    dkim.define_singleton_method(:private_key=) { |_| }
    dkim.define_singleton_method(:public_key=)  { |_| }
    dkim.define_singleton_method(:selector=)    { |_| }
    dkim.define_singleton_method(:save)         {}
    dkim.define_singleton_method(:public_key)   { saved_key }

    Smailr::Model::Domain.define_singleton_method(:[]) { |_| domain }
    Smailr::Model::Dkim.define_singleton_method(:for_domain!) do |fqdn, selector|
      for_domain_args << [fqdn, selector]
      dkim
    end

    Smailr::Dkim.add("example.com", "mail")

    assert_equal [["example.com", "mail"]], for_domain_args
  end

  def test_rm_destroys_dkim_record
    destroy_called = false

    dkim = Object.new
    dkim.define_singleton_method(:destroy) { destroy_called = true }

    Smailr::Model::Dkim.define_singleton_method(:for_domain) { |_fqdn, _sel| dkim }

    Smailr::Dkim.rm("example.com", "mx")

    assert destroy_called, "expected destroy to be called"
  end

  def test_rm_passes_fqdn_and_selector_to_for_domain
    for_domain_args = []
    dkim = Object.new
    dkim.define_singleton_method(:destroy) {}

    Smailr::Model::Dkim.define_singleton_method(:for_domain) do |fqdn, selector|
      for_domain_args << [fqdn, selector]
      dkim
    end

    Smailr::Dkim.rm("example.com", "mail")

    assert_equal [["example.com", "mail"]], for_domain_args
  end
end
