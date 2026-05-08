require_relative "test_helper"

class SmailrMailboxTest < Minitest::Test
  def setup
    @original_model = Smailr.const_get(:Model) if Smailr.const_defined?(:Model, false)
    Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)

    model = Module.new
    model.const_set(:Domain, Class.new)
    model.const_set(:Mailbox, Class.new)
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
      Smailr::Mailbox.add("user@example.com", "secret")
    end

    assert_includes error.message, "example.com"
  end

  def test_add_creates_mailbox_and_sets_password
    domain = Object.new
    password_set = nil
    saved = false

    mbox = Object.new
    mbox.define_singleton_method(:password=) { |pw| password_set = pw }
    mbox.define_singleton_method(:save)      { saved = true }

    Smailr::Model::Domain.define_singleton_method(:[]) { |_| domain }
    Smailr::Model::Mailbox.define_singleton_method(:for_address!) { |_| mbox }

    Smailr::Mailbox.add("user@example.com", "secret")

    assert_equal "secret", password_set
    assert saved, "expected save to be called"
  end

  def test_add_looks_up_domain_by_fqdn
    looked_up = []

    Smailr::Model::Domain.define_singleton_method(:[]) do |criteria|
      looked_up << criteria
      nil
    end

    assert_raises(Smailr::MissingDomain) do
      Smailr::Mailbox.add("user@example.com", "secret")
    end

    assert_equal [{ fqdn: "example.com" }], looked_up
  end

  def test_update_password_sets_password_and_saves
    password_set = nil
    saved = false

    mbox = Object.new
    mbox.define_singleton_method(:password=) { |pw| password_set = pw }
    mbox.define_singleton_method(:save)      { saved = true }

    Smailr::Model::Mailbox.define_singleton_method(:for_address) { |_| mbox }

    Smailr::Mailbox.update_password("user@example.com", "new-secret")

    assert_equal "new-secret", password_set
    assert saved, "expected save to be called"
  end

  def test_rm_destroys_mailbox_and_related_entries
    rm_related_called = false
    destroy_called    = false

    mbox = Object.new
    mbox.define_singleton_method(:rm_related) { rm_related_called = true }
    mbox.define_singleton_method(:destroy)    { destroy_called    = true }

    Smailr::Model::Mailbox.define_singleton_method(:for_address) { |_| mbox }

    Smailr::Mailbox.rm("user@example.com", TestOptions.new)

    assert rm_related_called, "expected rm_related to be called"
    assert destroy_called,    "expected destroy to be called"
  end
end
