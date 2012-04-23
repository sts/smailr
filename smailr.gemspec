Gem::Specification.new do |s|
    s.name              = 'smailr'
    s.version           = '0.0.1'
    s.date              = '2012-04-24'
    s.authors           = 'Stefan Schlesinger'
    s.email             = 'sts@ono.at'
    s.homepage          = 'http://github.com/sts/smailr'
    s.summary           = 'Simple MAIL manageR - Virtual mail hosting management from the CLI'
    s.description       = 'Smailr is a CLI tool which lets you manage your Exim/Dovecot setup
                           from the shell. It currently uses SQLite as a backend.'

    s.post_install_message = "

SMAILR ////////////////////////////////////////////////

To finish the installation copy the example Exim and
Dovecot configuration files from the contrib directory.

///////////////////////////////////////////////////////

"

    s.requirements << 'Exim'
    s.requirements << 'Dovecot'
    s.requirements << 'Debian'

    s.bindir       = 'bin'
    s.executables << 'smailr'

    s.files     = %w[
        bin
        bin/smailr
        contrib
        contrib/dovecot-sql.conf
        contrib/dovecot.conf
        contrib/exim4.conf
        Gemfile
        Gemfile.lock
        lib
        lib/smailr
        lib/smailr/alias.rb
        lib/smailr/domain.rb
        lib/smailr/mailbox.rb
        lib/smailr/model.rb
        lib/smailr.rb
        README.md
        smailr.gemspec
    ]

end
