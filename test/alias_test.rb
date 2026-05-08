require_relative "test_helper"

class SmailrAliasTest < Minitest::Test
  def setup
    @original_model = Smailr.const_get(:Model) if Smailr.const_defined?(:Model, false)
    Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)

    model = Module.new
    model.const_set(:Domain, Class.new)
    model.const_set(:Alias, Class.new)
    Smailr.const_set(:Model, model)

    @original_logger = Smailr.instance_variable_get(:@logger)
    Smailr.logger = Logger.new(File::NULL)
  end

  def teardown
    Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)
    Smailr.const_set(:Model, @original_model) if @original_model
    Smailr.instance_variable_set(:@logger, @original_logger)
  end

  def test_add_raises_missing_domain_for_unknown_source_domain
    Smailr::Model::Domain.define_singleton_method(:[]) do |_criteria|
      nil
    end

    error = assert_raises(Smailr::MissingDomain) do
      Smailr::Alias.add("alias@example.com", ["user@example.com"])
    end

    assert_equal(
      "You are trying to add an alias for a non existing domain: alias@example.com",
      error.message
    )
  end

  def test_add_creates_alias_record_for_each_destination
    domain = Object.new
    find_or_create_calls = []

    Smailr::Model::Domain.define_singleton_method(:[]) { |_| domain }
    Smailr::Model::Alias.define_singleton_method(:find_or_create) do |attrs|
      find_or_create_calls << attrs
    end

    Smailr::Alias.add("alias@example.com", ["user1@example.com", "user2@other.net"])

    assert_equal 2, find_or_create_calls.length

    first = find_or_create_calls[0]
    assert_same domain,        first[:domain]
    assert_equal "alias",      first[:localpart]
    assert_equal "user1",      first[:dstlocalpart]
    assert_equal "example.com", first[:dstdomain]

    second = find_or_create_calls[1]
    assert_same domain,       second[:domain]
    assert_equal "alias",     second[:localpart]
    assert_equal "user2",     second[:dstlocalpart]
    assert_equal "other.net", second[:dstdomain]
  end

  def test_rm_deletes_alias_record_for_each_destination
    domain = Object.new
    delete_calls = []

    filter_result = Object.new
    filter_result.define_singleton_method(:delete) { delete_calls << true }

    Smailr::Model::Domain.define_singleton_method(:[]) { |_| domain }
    Smailr::Model::Alias.define_singleton_method(:filter) do |attrs|
      filter_result
    end

    Smailr::Alias.rm("alias@example.com", ["user1@example.com", "user2@other.net"])

    assert_equal 2, delete_calls.length
  end

  def test_rm_passes_correct_attributes_to_filter
    domain = Object.new
    filter_calls = []

    filter_result = Object.new
    filter_result.define_singleton_method(:delete) {}

    Smailr::Model::Domain.define_singleton_method(:[]) { |_| domain }
    Smailr::Model::Alias.define_singleton_method(:filter) do |attrs|
      filter_calls << attrs
      filter_result
    end

    Smailr::Alias.rm("alias@example.com", ["user@other.net"])

    assert_equal 1, filter_calls.length
    attrs = filter_calls[0]
    assert_same domain,       attrs[:domain]
    assert_equal "alias",     attrs[:localpart]
    assert_equal "user",      attrs[:dstlocalpart]
    assert_equal "other.net", attrs[:dstdomain]
  end
end
