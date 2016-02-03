require 'commander'

module Smailr
    class Setup
        include Commander::Methods

        def run

            if Process.euid != 0
                say "ERROR: YOU ARE NOT RUNNING THIS SCRIPT WITH ROOT PRIVILEGES, EXITING."
                exit
            end

            # This is still hardcoded, required too much brainfuck to deal
            # with mulitple possible configuration files locations ATM.
            if File.exists?("/etc/smailr.yml")
                say "SYSTEM UPGRADE"
                say "---------------------------------------------------------------------------"
                say "You appear to already have a copy of smailr installed. Are you sure you want"
                say "proceed with the setup routine?"
                say ""
                say "This script is going to replace exim and dovecot configuration files"
                say "from /etc ; Backups of the existing config files will be created!"
                say ""
                say "FILES TO BE WRITTEN:"
                say ""
                say " - %s" % File.expand_path("exim4.conf", Smailr.config["exim_path"])
                say " - %s" % File.expand_path("dovecot.conf", Smailr.config["dovecot_path"])
                say " - %s" % File.expand_path("dovecot-sql.conf", Smailr.config["dovecot_path"])
                say ""
                if agree "Continue? [yes/no]"
                    defaults_file = "/etc/smailr.yml"
                else
                    exit
                end
            else
                defaults_file = File.expand_path("../smailr.yml", Smailr.contrib_directory)
            end

            setup_config(defaults_file)

            if Smailr.config["exim_path"]
                say "Setting up exim configuration in: #{Smailr.config['exim_path']}"
                setup_exim
            end

            if Smailr.config["dovecot_path"]
                say "Setting up dovecot configuration in: #{Smailr.config['dovecot_path']}"
                setup_dovecot
            end

            if Smailr.config["mail_spool_path"]
                say "Setting up mailspool user: vmail"
                say "Setting up mailspool directory structure in: #{Smailr.config['mail_spool_path']}"
                setup_mail_spool
            end

        end

        def self.setup_config(defaults_file)
            puts defaults_file
            defaults_fh = File.open(defaults_file, "r")
            defaults    = defaults_fh.read
            content     = ask_editor(defaults)

            create_file "/etc/smailr.yml",
                :content => content,
                :mode    => "0644",
                :owner   => "root",
                :group   => "root"

            Smailr.load_config
        end

        def self.setup_exim
            source = File.expand_path("exim4.conf", Smailr.contrib_directory)

            # Debian fucks up exim's name (exim4), and i really don't want to maintain a list
            # of possible filenames nor do i want the user to configure it ATM. :-/
            if Smailr.config["exim_path"].include?("exim4")
                file   = File.expand_path("exim4.conf", Smailr.config["exim_path"])
            else
                file   = File.expand_path("exim.conf", Smailr.config["exim_path"])
            end

            create_file file,
                :source => source,
                :mode => "0660",
                :owner => Smailr.config[:exim_user],
                :group => "root"
        end

        def self.setup_dovecot
            source = File.expand_path("dovecot.conf", Smailr.contrib_directory)
            file   = File.expand_path("dovecot.conf", Smailr.config["dovecot_path"])

            create_file file,
                :source => source,
                :mode   => "0660",
                :owner  => "root",
                :group  => "root"

            source = File.expand_path("dovecot-sql.conf", Smailr.contrib_directory)
            file   = File.expand_path("dovecot-sql.conf", Smailr.config["dovecot_path"])

            create_file file,
                :source => source,
                :mode   => "0660",
                :owner  => "root",
                :group  => "root"
        end

        def self.setup_mail_spool
            unless Etc.getpwnam("vmail")
                exec "useradd -r -d #{Smailr.config["mail_spool_path"]} vmail"
            end

            FileUtils.mkdir_p "#{Smailr.config["mail_spool_path"]}/users"
            FileUtils.chown "vmail", "vmail", Smailr.config["mail_spool_path"]
        end

        def self.create_file(file, opts)
            opts ||= {}

            if File.exists?(file)
                if File.writable?(File.dirname(file))
                    backstamp = Time.now.strftime("pre_smailr-%F-%R")
                    say "Creating backup of existing configuration: #{file}.#{backstamp}"
                    FileUtils.mv file, "#{file}.#{backstamp}"
                else
                    say_error "Cannot write to directory #{File.dirname(file)}."
                    exit 1
                end
            end

            if File.directory?(File.dirname(file))
                if File.writable?(File.dirname(file))
                    say "Installing configuration file: #{file}"

                    # COPY
                    if opts[:source]
                        FileUtils.cp opts[:source], file
                    end

                    # CREATE
                    if opts[:content]
                        File.open(file, 'w') {|f| f.write(opts[:content]) }
                    end

                    # MODE
                    FileUtils.chmod opts[:mode], file  if opts[:mode]

                    # USER
                    FileUtils.chown opts[:owner], nil, file if opts[:owner]

                    # GROUP
                    FileUtils.chown nil, opts[:group], file if opts[:group]
                else
                    say_error "Cannot create configuration file in #{File.dirname(file)}, permission denied."
                    say_error "Please repair the permissions, run with sudo or as root. Run setup again."
                    exit 1
                end
            else
                say_error "Directory does not exist: #{File.dirname(file)}."
                say_error "Please check your configuration and run setup again."
                exit 1
            end
        end
    end
end
