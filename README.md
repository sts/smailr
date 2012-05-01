# Smailr - A Virtual Mail Hosting Management CLI (ALPHA)

Smailr is a small CLI application, which lets you manage the database for a
typical Exim/Dovecot stack.

Configuration files are provided within the contrib directory, so you should be
able to get everything up and running within a couple of minutes.

Please note, Smailr is still in development!

## Installation

Install Exim and Dovecot

    aptitude install exim-daemon-heavy dovecot-imapd dovecot-pop3d

Install the example Exim and Dovecot configration files on your mailserver.

    cp contrib/exim4.conf /etc/exim4/exim4.conf
    chown root:Debian-exim /etc/exim4/exim4.conf
    cp contrib/dovecot* /etc/dovecot/
    invoke-rc.d exim4 restart
    invoke-rc.d dovecot restart

Add a user which will own the mails and is used for the LDA

    useradd -r -d /srv/mail vmail
    mkdir /srv/mail/users
    chown -R vmail:vmail /srv/mail

Run the setup command to initialize the smailr database

    # Creates /etc/exim4/smailr.sqlite
    smailr migrate

Add a domain and an user to your database using the commands listed below.


## Managing your mailserver

### Domains

Add a local domain

    smailr add example.com

Remove a local domain and all associated mailboxes

    smailr rm example.com

List all domains

    smailr ls

### Mailboxes

Add a new local mailbox. This will interactively ask you for the user password

    smailr add user@example.com

You can as well specify the password on the CLI

    smailr add user@example.com --password secretpass

Remove a local mailbox

    smailr rm user@example.com

List all addresses for a domain

    smailr ls example.com

### Aliases

Simply add an 'user-alias@example.com' alias to the 'user@example.com' mailbox.

    smailr add user-alias@example.com --alias user@example.com

To remove the alias again, run the rm command.

    smailr rm user-alias@example.com --alias user@example.com

You can as well specify multiple destinations for both commands separated by a comma:

    smailr add user-alias@example.com --alias user@example.com,user1@example.com

### Mutt

Smailr can launch mutt with the required configuration for a specific mailbox
automatically. Open mutt for the specified mailbox:

    smailr mutt user@example.com

## BUGS

For bugs or feature requests, please use the GitHub issue tracker.

https://github.com/sts/smailr/issues


## WHO

Stefan Schlesinger / sts@ono.at / @stsonoat / http://sts.ono.at

