$LOAD_PATH.unshift(File.expand_path("support", __dir__))
$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "minitest/autorun"
require "minitest/mock"
require "net/smtp"
require "open3"
require "rbconfig"
require "socket"

class TestOptions
  def initialize(values = {})
    @values = values.transform_keys(&:to_sym)
  end

  def default(values)
    values.each do |key, value|
      @values[key.to_sym] = value if @values[key.to_sym].nil?
    end
  end

  def [](key)
    @values[key.to_sym]
  end

  def []=(key, value)
    @values[key.to_sym] = value
  end

  def method_missing(name, *args)
    if name.to_s.end_with?("=")
      @values[name.to_s.delete_suffix("=").to_sym] = args.first
      return args.first
    end

    key = name.to_sym
    return @values[key] if args.empty? && @values.key?(key)
    return nil if args.empty?

    super
  end

  def respond_to_missing?(name, include_private = false)
    @values.key?(name.to_sym) || super
  end
end

require "sequel/extensions/migration"
require "smailr"
require "smailr/cli"
