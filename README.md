# Smailr - A Virtual Mail Hosting Management CLI

Smailr is a small CLI application, which lets you manage a typical Exim / Dovecot stack.


## Installation

 * Install the attached exim and dovecot configration files on your mailserver.

 * Run the setup command

    smailr setup sqlite:///etc/exim/smailr.sqlite3


## Managing Domains and Users

## Domain Object

    smailr domain add example.com

    smailr domain list

    smailr domain rm example.com

## Mailbox Object

    smailr mbox add user@example.com secretpass

    smailr mbox rm user@example.com

    smailr mbox list example.com

