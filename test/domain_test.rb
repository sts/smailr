require_relative "test_helper"

class SmailrDomainTest < Minitest::Test
  def setup
    @original_model = Smailr.const_get(:Model) if Smailr.const_defined?(:Model, false)
    Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)

    model = Module.new
    model.const_set(:Domain, Class.new)
    Smailr.const_set(:Model, model)

    @original_logger = Smailr.instance_variable_get(:@logger)
    Smailr.logger = Logger.new(File::NULL)
  end

  def teardown
    Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)
    Smailr.const_set(:Model, @original_model) if @original_model
    Smailr.instance_variable_set(:@logger, @original_logger)
  end

  def test_add_creates_domain_record_with_fqdn
    created = []

    Smailr::Model::Domain.define_singleton_method(:create) { |attrs| created << attrs }

    Smailr::Domain.add("example.com")

    assert_equal [{ fqdn: "example.com" }], created
  end

  def test_rm_destroys_domain_and_related_entries_when_forced
    rm_related_called = false
    destroy_called = false

    domain = Object.new
    domain.define_singleton_method(:rm_related) { rm_related_called = true }
    domain.define_singleton_method(:destroy)    { destroy_called    = true }

    Smailr::Model::Domain.define_singleton_method(:[]) { |_| domain }

    Smailr::Domain.rm("example.com", true)

    assert rm_related_called, "expected rm_related to be called"
    assert destroy_called,    "expected destroy to be called"
  end

  def test_rm_does_nothing_when_not_forced
    Smailr::Domain.rm("example.com", false)
    Smailr::Domain.rm("example.com")
  end

  def test_rm_without_force_does_not_look_up_domain
    Smailr::Model::Domain.define_singleton_method(:[]) { |_| raise "should not be called" }

    Smailr::Domain.rm("example.com", false)
  end
end
