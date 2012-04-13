# Smailr - A Virtual Mail Hosting Management CLI

Smailr is a small CLI application, which lets you manage a typical Exim / Dovecot stack.
This is still in development.

## Installation

 * Install Exim and Dovecot

    aptitude install exim-daemon-heavy dovecot-imapd dovecot-pop3d

 * Install the example Exim and Dovecot configration files on your mailserver.

    cp contrib/exim4.conf /etc/exim4/exim4.conf
    chown root:Debian-exim/etc/exim4/exim4.conf
    cp contrib/dovecot* /etc/dovecot/
    invoke-rc.d exim4 restart
    invoke-rc.d dovecot restart

 * Run the setup command to initialize the smailr database in 

    # Creates /etc/exim4/smailr.sqlite
    smailr setup

 * Add a domain and a user


## Managing Domains and Users

### Domain Object

    smailr domain add example.com

    smailr domain list

    smailr domain rm example.com

### Mailbox Object

    smailr mbox add user@example.com secretpass

    smailr mbox rm user@example.com

    smailr mbox list example.com


## BUGS

For bugs or feature requests, please use the GitHub issue tracker.

https://github.com/sts/smailr/issues


## WHO

Stefan Schlesinger / sts@ono.at / @stsonoat / http://sts.ono.at

