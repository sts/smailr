# Smailr - A Virtual Mail Hosting Management CLI

Smailr is a small CLI application, which lets you manage a typical Exim / Dovecot stack.

I personally dont really like installing a webserver and mysql for my personal mailserver,
and I dont need advanced features of vexim 

This is still in development.

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

Run the setup command to initialize the smailr database in 

    # Creates /etc/exim4/smailr.sqlite
    smailr setup

Add a domain and an user to your database using the commands listed below.


## Managing Domains and Users

### Domains

    smailr add example.com

    smailr rm example.com

### Mailbox Object

    smailr add user@example.com

    smailr rm user@example.com


## BUGS

For bugs or feature requests, please use the GitHub issue tracker.

https://github.com/sts/smailr/issues


## WHO

Stefan Schlesinger / sts@ono.at / @stsonoat / http://sts.ono.at

