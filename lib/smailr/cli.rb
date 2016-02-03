require 'commander'

module Smailr
  class Cli

    include Commander::Methods

    ## Our own CLI Helpers

    # Determine whether we the passed string is a domain or a mail
    # address.
    #
    # Returns either :domain or :address
    def determine_object(string)
        return :domain  if string =~ /^[^@][A-Z0-9.-]+\.[A-Z]{2,6}$/i
        return :address if string =~ /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,6}$/i
    end

    # Run an interactive cli dialog to enter and confirm a password.
    #
    # Returns a string containing the entered password if password and
    # confirmation match.
    def ask_password
        min_password_length = Smailr.config["password_policy"]["length"]

        password = ask("Password: ") { |q| q.echo = "*" }
        confirm  = ask("Confirm: ")  { |q| q.echo = "*" }

        if password != confirm
            say("Mismatch; try again.")
            ask_password
        end

        if password.length < min_password_length.to_i
            say("Too short; try again.")
            ask_password
        end

        password
    end

    # Initialize the Cli
    def run
      program :description, 'smailr - Virtual Mail Hosting Management CLI'
      program :version, Smailr::VERSION

      ### Commands

      command :add do |c|
        c.syntax = 'smailr add domain | mailbox | alias [options]'
        c.summary = 'Add a new domain, mailbox or alias to the mail system.'
        c.example 'Add a domain',  'smailr add example.com'
        c.example 'Add a mailbox', 'smailr add user@example.com'
        c.example 'Add an alias',  'smailr add alias@localdom.com --alias user@example.com,user1@example.com'
        c.example 'Setup DKIM for a domain', 'smailr add ono.at --dkim'
        c.option  '--alias DESTINATION', String, 'Specify the alias destination.'
        c.option  '--password PASSWORD', String, 'The password for a new mailbox. If you omit this option, it prompts for one.'
        c.option  '--dkim SELECTOR',     String, 'Add a DKIM Key with the specified selector for domain.'
        c.action do |args, options|
          address = args[0]
          type    = determine_object(address)

          case type
            when :domain
              if options.dkim
                selector = options.dkim
                key = Smailr::Dkim.add(address, selector)

                puts "public-key " + key.split("\n").slice(1..-2).join
              else
                Smailr::Domain.add(address)
              end

            when :address
              if options.alias
                source       = args[0]
                destinations = options.alias.split(',')
                Smailr::Alias.add(source, destinations)
              else
                options.password ||= ask_password
                Smailr::Mailbox.add(address, options.password)
              end

          end
        end
      end

      command :ls do |c|
        c.syntax  = 'smailr ls [domain]'
        c.summary = 'List domains or mailboxes and aliases of a specific domain.'
        c.action do |args, options|
          case args[0]
          when /^[^@][A-Z0-9.-]+\.[A-Z]{2,6}$/i then
            domain = Smailr::Model::Domain[:fqdn => args[0]]
            domain.mailboxes.each do |mbox|
              puts "m: #{mbox.localpart}@#{args[0]}"
            end
            domain.aliases.each do |aliass|
              puts "a: #{aliass.localpart}@#{args[0]} > #{aliass.dstlocalpart}@#{aliass.dstdomain}"
            end
          when nil
            domains = Smailr::DB[:domains]
            domains.all.each do |d|
              domain = Smailr::Model::Domain[:fqdn => d[:fqdn]]
              puts d[:fqdn]
            end
          else
            error "You can either list a domains or a domains addresses."
            exit 1
          end
        end
      end

      command :rm do |c|
        c.syntax  = 'smailr rm domain | mailbox [options]'
        c.summary = 'Remove a domain, mailbox or alias known to the mail system.'
        c.example 'Remove a domain', 'smailr rm example.com'
        c.option '--force', 'Force the operation, do not ask for confirmation.'
        c.option '--dkim SELECTOR',  String, 'Remove a dkim key.' 
        c.option '--alias DESTINATION', String, 'Specify the destination you want to remove from the alias.'
        c.action do |args, options|
          address = args[0]
          type    = determine_object(address)
          case type
          when :domain
            if options.dkim
              selector = options.dkim
              Smailr::Dkim.rm(address, selector)
            else
              Smailr::Domain.rm(address, options.force)
            end

          when :address
            if options.alias
              source       = args[0]
              destinations = options.alias.split(',')

              Smailr::Alias.rm(source, destinations)
            else
              Smailr::Mailbox.rm(address, options)
            end
          end
        end
      end

      command :passwd do |c|
        c.syntax  = 'smailr passwd mailbox'
        c.summary = 'Update a users password.'
        c.action do |args,options|
          address  = args[0]
          password = ask_password
          Smailr::Mailbox.update_password(address, password)
        end
      end


      command :setup do |c|
        c.syntax  = 'smailr setup'
        c.summary = 'Install all required components on a mailserver'
        c.action do |args,options|
          Smailr::Setup.new.run
        end
      end


      command :migrate do |c|
        c.syntax  = 'smailr migrate [options]'
        c.summary = 'Create database and run migrations'
        c.option '--to VERSION', String, 'Migrate the database to a specifict version.'
        c.action do |args,options|
          require 'sequel/extensions/migration'
          raise "Database not configured" unless Smailr::DB

          if options.to.nil?
            if Sequel::Migrator.is_current?(Smailr::DB, Smailr.migrations_directory)
              puts "Database schema already up to date. Exiting"
              exit 0
            end

            puts "Running database migrations to latest version."
            Sequel::Migrator.apply(Smailr::DB, Smailr.migrations_directory)
          else
            puts "Running database migrations to version: #{options.to}"
            Sequel::Migrator.apply(Smailr::DB, Smailr.migrations_directory, options.to.to_i)
          end
        end
      end


      command :mutt do |c|
        base = Smailr.config["mail_spool_path"]

        c.syntax      = "smailr mutt address"
        c.summary     = "View the mailbox of the specified address in mutt."
        c.description = "Open the mailbox of the specified address in mutt.\n\n    " +
          "Requires that mutt is installed and tries to find a suitable maildir in: " + base
        c.example       'Open test@example.com', 'smailr mutt test@example.com'
        c.action do |args,options|
          localpart, fqdn = args[0].split('@')

          mutt = `command -v mutt || { echo "Please install mutt first. Aborting." >&2; exit 1; }`
          if $?

            possibilities = [
              "#{base}/#{fqdn}/#{localpart}/Maildir",
            "#{base}/users/#{fqdn}/#{localpart}/Maildir",
            "#{base}/users/#{fqdn}/#{localpart}/.maildir",
            "#{base}/users/#{fqdn}/#{localpart}"
          ]

            possibilities.each do |path|
              if File.readable?(path)
                puts "Opening maildir #{path} with mutt."
                exec "MAIL=#{path} MAILDIR=#{path} #{mutt} -mMaildir"
              end
            end
          end
        end
      end

      command :verify do |c|
        c.syntax      = "smailr verify address"
        c.summary     = "Send out a test message to verify a domains configuration via verifier.port25.com"
        c.description = "A reply email will be sent back to you with an analysis of the message’s authentication" +
          "status.  The report will perform the following checks: SPF, SenderID, DomainKeys, DKIM " +
          "and Spamassassin.\n\n"
        c.example       'Verify test@example.com (report will be sent to test@example.com)', 'smailr verify test@example.com'
        c.example       'Verify test@example.com, send report to root@example.com', 'smailr verify test@example.com --report-to root@example.com'

        c.option        '-r DESTINATION', '--report-to DESTINATION', String, 'Send the report to the specified address instead.'

        c.action do |args,options|
          from = args[0]
          options.default :report_to => from

          dstlocalpart, dstfqdn = options.report_to.split('@')

          require 'socket'
          require 'date'
          require 'net/smtp'
          Net::SMTP.start('localhost', 25) do |smtp|
            to = "check-auth-#{dstlocalpart}=#{dstfqdn}@verifier.port25.com"

            message = [
              "From: #{from}",
              "To: #{to}",
              "Subject: Port25 Mail Verification Test",
                "Date: #{DateTime.now.strftime("%a, %d %b %Y %H:%M:%S %z")}",
              "",
                "This is a test message for the port25 mail verification test, it was",
                "sent from the following server: #{Socket.gethostname}."
            ].join("\r\n")

            smtp.send_message(message, from, to)
          end
        end
      end

      run!
    end
  end
end
