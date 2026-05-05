require_relative "test_helper"

class SmailrAliasTest < Minitest::Test
  def setup
    @original_model = Smailr.const_get(:Model) if Smailr.const_defined?(:Model, false)
    Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)

    model = Module.new
    model.const_set(:Domain, Class.new)
    model.const_set(:Alias, Class.new)
    Smailr.const_set(:Model, model)
  end

  def teardown
    Smailr.send(:remove_const, :Model) if Smailr.const_defined?(:Model, false)
    Smailr.const_set(:Model, @original_model) if @original_model
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
end
