# -*- encoding: utf-8 -*-
$: <<  File.expand_path('../lib', __FILE__)

require 'smailr'

Gem::Specification.new do |s|
    s.name              = 'smailr'
    s.version           = Smailr::VERSION
    s.date              = '2016-01-19'
    s.authors           = 'Stefan Schlesinger'
    s.email             = 'sts@ono.at'
    s.homepage          = 'http://github.com/sts/smailr'
    s.summary           = 'Simple MAIL manageR - Virtual mail hosting management from the CLI'
    s.description       = 'Smailr is a CLI tool which lets you manage your virtual mailhosting setup
                           from the shell. It currently uses SQLite as a backend, samples for Dovecot/Exim provided.'

    s.license           = 'Apache-2.0'
    s.has_rdoc          = false
    s.files             = Dir.glob("{bin,lib,contrib,migrations}/**/*") + %w{README.md smailr.yml}
    s.bindir            = 'bin'

    s.executables       << 'smailr'
    s.add_runtime_dependency 'commander', '~> 4.3'
    s.add_runtime_dependency 'sequel', '~> 4.26'
    s.add_runtime_dependency 'bcrypt', '~> 3.1'

    s.requirements      << 'Exim'
    s.requirements      << 'Dovecot'

    s.post_install_message = '

SMAILR /////////////////////////////////////////////////////////////////

 TO FINISH THE LOCAL SMAILR INSTALLATION:

  * Install Exim with SQLite support

  * Install Dovecot with SQlite support

  * run ln -s `gem contents smailr|grep bin/smailr` /usr/local/sbin

  * run "smailr setup" to create exim, dovecot and smailr configuration (you
    can edit the configuration in an editor window before everyting is
    initialized)

  * run "smailr migrate" to initialize the database file

//////////////////////////////////////////////////////////////// ///////

'

end
