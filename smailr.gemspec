# -*- encoding: utf-8 -*-
$: <<  File.expand_path('../lib', __FILE__)

require 'smailr'

Gem::Specification.new do |s|
    s.name              = 'smailr'
    s.version           = Smailr::VERSION
    s.date              = '2012-04-26'
    s.authors           = 'Stefan Schlesinger'
    s.email             = 'sts@ono.at'
    s.homepage          = 'http://github.com/sts/smailr'
    s.summary           = 'Simple MAIL manageR - Virtual mail hosting management from the CLI'
    s.description       = 'Smailr is a CLI tool which lets you manage your Exim/Dovecot setup
                           from the shell. It currently uses SQLite as a backend.'

    s.has_rdoc          = false
    s.files             = Dir.glob("{bin,lib,contrib,migrations}/**/*") + %w{README.md smailr.yml}

    s.bindir            = 'bin'
    s.executables       << 'smailr'

    s.add_dependency    'commander'
    s.add_dependency    'sqlite3'
    s.add_dependency    'sequel'

    s.requirements      << 'Exim'
    s.requirements      << 'Dovecot'
    s.requirements      << 'Debian'

    s.post_install_message = "

SMAILR /////////////////////////////////////////////////////////////////

   To finish the installation copy the example Exim and Dovecot
   configuration files from the contrib directory and run
   'smailr migrate' to initialize the database.

//////////////////////////////////////////////////////////////// ///////

"

end
