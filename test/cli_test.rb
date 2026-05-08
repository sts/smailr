require_relative "test_helper"

class SmailrCliTest < Minitest::Test
  MailboxRow = Struct.new(:localpart)
  AliasRow = Struct.new(:localpart, :dstlocalpart, :dstdomain)
  DomainRow = Struct.new(:mailboxes, :aliases)

  def setup
    Smailr.config = {
      "password_policy" => { "length" => 5 },
      "mail_spool_path" => "/srv/mail"
    }
    Smailr.migrations_directory = "/tmp/migrations"

    replace_db(nil)

    ensure_class("Smailr::Domain")
    ensure_class("Smailr::Mailbox")
    ensure_class("Smailr::Alias")
    ensure_class("Smailr::Dkim")
    ensure_class("Smailr::Setup")
    ensure_module("Smailr::Model")
    ensure_class("Smailr::Model::Domain")
    define_stubbed_singleton_methods(Smailr::Domain, :add, :rm)
    define_stubbed_singleton_methods(Smailr::Mailbox, :add, :rm, :update_password)
    define_stubbed_singleton_methods(Smailr::Alias, :add, :rm)
    define_stubbed_singleton_methods(Smailr::Dkim, :add, :rm)
    define_stubbed_singleton_methods(Smailr::Model::Domain, :[])
    define_stubbed_singleton_methods(Sequel::Migrator, :is_current?, :apply)

    @cli = Smailr::Cli.new
    @cli.run
  end

  def teardown
    replace_db(nil)
  end

  def test_registers_all_commands
    assert_equal %i[add ls rm passwd setup migrate mutt verify], @cli.commands.keys
  end

  def test_add_domain_command_calls_domain_add
    calls = []

    Smailr::Domain.stub(:add, ->(address) { calls << address }) do
      invoke(:add, ["example.com"])
    end

    assert_equal ["example.com"], calls
  end

  def test_add_domain_with_dkim_calls_dkim_add_and_prints_dns_record
    out, = capture_io do
      Smailr::Dkim.stub(:add, "-----BEGIN PUBLIC KEY-----\nMIIB\n-----END PUBLIC KEY-----\n") do
        invoke(:add, ["example.com"], dkim: "mx")
      end
    end

    assert_includes out, "DKIM is active now"
    assert_includes out, "mx._domainkey IN TXT"
    assert_includes out, "p=MIIB"
  end

  def test_add_mailbox_with_explicit_password_calls_mailbox_add
    calls = []

    Smailr::Mailbox.stub(:add, ->(address, password) { calls << [address, password] }) do
      invoke(:add, ["user@example.com"], password: "secret")
    end

    assert_equal [["user@example.com", "secret"]], calls
  end

  def test_add_mailbox_without_password_prompts_via_helper
    calls = []

    @cli.stub(:ask_password, "secret") do
      Smailr::Mailbox.stub(:add, ->(address, password) { calls << [address, password] }) do
        invoke(:add, ["user@example.com"])
      end
    end

    assert_equal [["user@example.com", "secret"]], calls
  end

  def test_ask_password_retries_until_valid_password_is_entered
    answers = %w[shrt shrt correctpw correctpw]
    prompts = []

    @cli.define_singleton_method(:ask) do |prompt, &_block|
      prompts << prompt
      answers.shift
    end

    out, = capture_io do
      password = @cli.ask_password
      assert_equal "correctpw", password
    end

    assert_equal ["Password: ", "Confirm: ", "Password: ", "Confirm: "], prompts
    assert_includes out, "Too short; try again."
  end

  def test_add_alias_splits_destinations
    calls = []

    Smailr::Alias.stub(:add, ->(source, destinations) { calls << [source, destinations] }) do
      invoke(:add, ["alias@example.com"], alias: "user1@example.com,user2@example.com")
    end

    assert_equal [["alias@example.com", ["user1@example.com", "user2@example.com"]]], calls
  end

  def test_ls_lists_mailboxes_and_aliases_for_domain
    domain = DomainRow.new(
      [MailboxRow.new("user")],
      [AliasRow.new("alias", "user", "example.net")]
    )

    out, = capture_io do
      Smailr::Model::Domain.stub(:[], domain) do
        invoke(:ls, ["example.com"])
      end
    end

    assert_includes out, "m: user@example.com"
    assert_includes out, "a: alias@example.com > user@example.net"
  end

  def test_ls_with_unknown_domain_exits_with_error
    error = nil

    _, stderr = capture_io do
      Smailr::Model::Domain.stub(:[], nil) do
        error = assert_raises(SystemExit) do
          invoke(:ls, ["asdf.com"])
        end
      end
    end

    assert_equal 1, error.status
    assert_includes stderr, "No such domain: asdf.com"
  end

  def test_ls_lists_all_domains_without_argument
    dataset = Object.new
    dataset.define_singleton_method(:all) do
      [{ fqdn: "example.com" }, { fqdn: "example.net" }]
    end

    db = Object.new
    db.define_singleton_method(:[]) do |_table|
      dataset
    end

    replace_db(db)

    out, = capture_io do
      Smailr::Model::Domain.stub(:[], nil) do
        invoke(:ls)
      end
    end

    assert_equal ["example.com", "example.net"], out.lines.map(&:chomp)
  end

  def test_ls_with_invalid_argument_exits_with_error
    error = nil

    _, stderr = capture_io do
      error = assert_raises(SystemExit) do
        invoke(:ls, ["not-an-address"])
      end
    end

    assert_equal 1, error.status
    assert_includes stderr, "You can either list a domains or a domains addresses."
  end

  def test_rm_domain_calls_domain_rm_with_force_option
    calls = []

    Smailr::Domain.stub(:rm, ->(address, force) { calls << [address, force] }) do
      invoke(:rm, ["example.com"], force: true)
    end

    assert_equal [["example.com", true]], calls
  end

  def test_rm_domain_with_dkim_calls_dkim_rm
    calls = []

    Smailr::Dkim.stub(:rm, ->(address, selector) { calls << [address, selector] }) do
      invoke(:rm, ["example.com"], dkim: "mx")
    end

    assert_equal [["example.com", "mx"]], calls
  end

  def test_rm_mailbox_calls_mailbox_rm
    calls = []
    options = TestOptions.new

    Smailr::Mailbox.stub(:rm, ->(address, passed_options) { calls << [address, passed_options] }) do
      command(:rm).call(["user@example.com"], options)
    end

    assert_equal [["user@example.com", options]], calls
  end

  def test_rm_alias_splits_destinations
    calls = []

    Smailr::Alias.stub(:rm, ->(source, destinations) { calls << [source, destinations] }) do
      invoke(:rm, ["alias@example.com"], alias: "user1@example.com,user2@example.com")
    end

    assert_equal [["alias@example.com", ["user1@example.com", "user2@example.com"]]], calls
  end

  def test_passwd_updates_mailbox_password
    calls = []

    @cli.stub(:ask_password, "new-secret") do
      Smailr::Mailbox.stub(:update_password, ->(address, password) { calls << [address, password] }) do
        invoke(:passwd, ["user@example.com"])
      end
    end

    assert_equal [["user@example.com", "new-secret"]], calls
  end

  def test_setup_runs_setup_object
    ran = false
    setup = Object.new
    setup.define_singleton_method(:run) do
      ran = true
    end

    Smailr::Setup.stub(:new, setup) do
      invoke(:setup)
    end

    assert ran
  end

  def test_migrate_exits_when_schema_is_current
    replace_db(Object.new)

    Sequel::Migrator.stub(:is_current?, true) do
      Sequel::Migrator.stub(:apply, ->(*) { flunk("did not expect apply") }) do
        error = nil

        out, = capture_io do
          error = assert_raises(SystemExit) do
            invoke(:migrate)
          end
        end

        assert_equal 0, error.status
        assert_includes out, "Database schema already up to date. Exiting"
      end
    end
  end

  def test_migrate_applies_latest_when_schema_is_outdated
    replace_db(:db)
    calls = []

    Sequel::Migrator.stub(:is_current?, false) do
      Sequel::Migrator.stub(:apply, ->(*args) { calls << args }) do
        out, = capture_io do
          invoke(:migrate)
        end

        assert_includes out, "Running database migrations to latest version."
      end
    end

    assert_equal [[:db, "/tmp/migrations"]], calls
  end

  def test_migrate_applies_requested_version
    replace_db(:db)
    calls = []

    Sequel::Migrator.stub(:apply, ->(*args) { calls << args }) do
      out, = capture_io do
        invoke(:migrate, [], to: "12")
      end

      assert_includes out, "Running database migrations to version: 12"
    end

    assert_equal [[:db, "/tmp/migrations", 12]], calls
  end

  def test_mutt_execs_mutt_for_first_readable_maildir
    system("true")
    exec_calls = []
    expected_path = "/srv/mail/example.com/user/Maildir"

    out, = capture_io do
      @cli.stub(:`, "/usr/bin/mutt\n") do
        @cli.stub(:exec, ->(command) { exec_calls << command }) do
          File.stub(:readable?, ->(path) { path == expected_path }) do
            invoke(:mutt, ["user@example.com"])
          end
        end
      end
    end

    assert_includes out, "Opening maildir #{expected_path} with mutt."
    assert_equal ["MAIL=#{expected_path} MAILDIR=#{expected_path} /usr/bin/mutt\n -mMaildir"], exec_calls
  end

  def test_verify_sends_message_to_default_report_destination
    sent = {}

    Net::SMTP.stub(:start, lambda { |host, port, &block|
      smtp = Object.new
      smtp.define_singleton_method(:send_message) do |message, from, to|
        sent[:host] = host
        sent[:port] = port
        sent[:message] = message
        sent[:from] = from
        sent[:to] = to
      end
      block.call(smtp)
    }) do
      Socket.stub(:gethostname, "test-host") do
        invoke(:verify, ["user@example.com"])
      end
    end

    assert_equal "localhost", sent[:host]
    assert_equal 25, sent[:port]
    assert_equal "user@example.com", sent[:from]
    assert_equal "check-auth-user=example.com@verifier.port25.com", sent[:to]
    assert_includes sent[:message], "From: user@example.com"
    assert_includes sent[:message], "sent from the following server: test-host."
  end

  def test_verify_uses_report_to_override
    sent = {}

    Net::SMTP.stub(:start, lambda { |_host, _port, &block|
      smtp = Object.new
      smtp.define_singleton_method(:send_message) do |_message, _from, to|
        sent[:to] = to
      end
      block.call(smtp)
    }) do
      Socket.stub(:gethostname, "test-host") do
        invoke(:verify, ["user@example.com"], report_to: "root@example.net")
      end
    end

    assert_equal "check-auth-root=example.net@verifier.port25.com", sent[:to]
  end

  def test_determine_object_returns_domain_for_domain_string
    assert_equal :domain, @cli.determine_object("example.com")
    assert_equal :domain, @cli.determine_object("sub.example.com")
    assert_equal :domain, @cli.determine_object("my-host.example.org")
  end

  def test_determine_object_returns_address_for_email_string
    assert_equal :address, @cli.determine_object("user@example.com")
    assert_equal :address, @cli.determine_object("user.name+tag@example.org")
  end

  def test_determine_object_returns_nil_for_unrecognized_input
    assert_nil @cli.determine_object("not-valid")
    assert_nil @cli.determine_object("@badformat")
    assert_nil @cli.determine_object("justtext")
  end

  def test_ask_password_retries_when_passwords_do_not_match
    answers = %w[password1 different password1 password1]
    prompts = []

    @cli.define_singleton_method(:ask) do |prompt, &_block|
      prompts << prompt
      answers.shift
    end

    out, = capture_io do
      password = @cli.ask_password
      assert_equal "password1", password
    end

    assert_equal ["Password: ", "Confirm: ", "Password: ", "Confirm: "], prompts
    assert_includes out, "Mismatch; try again."
  end

  def test_add_does_nothing_for_unrecognized_argument_type
    out, = capture_io do
      invoke(:add, ["not-a-valid-argument"])
    end

    assert_empty out.strip
  end

  def test_rm_does_nothing_for_unrecognized_argument_type
    out, = capture_io do
      invoke(:rm, ["not-a-valid-argument"])
    end

    assert_empty out.strip
  end

  private

  def command(name)
    @cli.commands.fetch(name)
  end

  def invoke(name, args = [], options = {})
    command(name).call(args, TestOptions.new(options))
  end

  def ensure_class(name)
    ensure_constant(name, Class.new)
  end

  def ensure_module(name)
    ensure_constant(name, Module.new)
  end

  def ensure_constant(name, value)
    names = name.split("::")
    const_name = names.pop
    parent = names.inject(Object) do |scope, segment|
      scope.const_get(segment)
    end

    return if parent.const_defined?(const_name, false)

    parent.const_set(const_name, value)
  end

  def replace_db(value)
    Smailr.send(:remove_const, :DB) if Smailr.const_defined?(:DB, false)
    Smailr.const_set(:DB, value)
  end

  def define_stubbed_singleton_methods(target, *methods)
    methods.each do |method_name|
      next if target.respond_to?(method_name)

      target.define_singleton_method(method_name) do |*|
        raise NotImplementedError, "#{target}.#{method_name} must be stubbed in tests"
      end
    end
  end
end
