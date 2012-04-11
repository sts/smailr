# Smailr - A Virtual Mail Hosting Management CLI

Smailr is a small CLI application, which lets you manage a typical Exim / Dovecot stack.
This is still in development.

## Installation

 * Install the attached exim and dovecot configration files on your mailserver.

 * Run the setup command

    cd /etc/exim4
    smailr setup


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

