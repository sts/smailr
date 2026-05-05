module Commander
  class Command
    attr_accessor :syntax, :summary, :description
    attr_reader :name, :examples, :options, :action_block

    def initialize(name)
      @name = name.to_sym
      @examples = []
      @options = []
    end

    def example(description, command)
      @examples << [description, command]
    end

    def option(*definition)
      @options << definition
    end

    def action(&block)
      @action_block = block
    end

    def call(args, options)
      action_block.call(args, options)
    end
  end

  module Methods
    def program(*)
    end

    def command(name)
      commands[name.to_sym] = Command.new(name)
      yield commands[name.to_sym] if block_given?
      commands[name.to_sym]
    end

    def commands
      @commands ||= {}
    end

    def run!
      self
    end

    def say(message = "")
      $stdout.puts(message)
    end

    def error(message)
      $stderr.puts(message)
    end

    def say_error(message)
      error(message)
    end
  end
end
