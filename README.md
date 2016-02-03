# Smailr - A Virtual Mail Hosting Management CLI

Smailr is a small CLI application, which lets you manage the database for a
typical mailserver (examples provided for Exim/Dovecot).

Configuration files are provided within the contrib directory, so you should be
able to get everything up and running within a couple of minutes.

## Installation

Install Packages

    # aptitude install exim4-daemon-heavy dovecot-imapd dovecot-pop3d

    # aptitude install rubygems libsqlite3-dev ruby-sqlite3

Install Smailr Gem package

    # gem install smailr

Generate the Smailr configuration in /etc/smailr.yml

    # smailr setup

please review the configuration file, then run 'setup' again:

    # smailr setup

To initialize the database run all migrations

    # smailr migrate

You should now be ready to just manage your mailserver with the commands listed
below.

## Configuration

Smailr is configured in /etc/smailr.yml, thats where you can configure your
database backend. By default smailr will use the following sqlite datbase:

    database:
        adapter:  sqlite
        database: /etc/exim4/smailr.sqlite

The configuration files in the contrib directory are configured to work with
this database.

But you can configure any other database as well. Eg. for MySQL use:

    database:
        adapter: mysql2
        host: localhost
        username: smailr
        database: smailr
        password: S3cr3t

Just make sure the database driver is installed (for MySQL: aptitude install
ruby-mysql2). Smailr uses the Sequel ORM, check out the following page for
connection parameters: [sequel.jeremyevans.net/opening_databases_rdoc](http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html)

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

Update a users passowrd

    smailr passwd user@example.com

### Aliases

Simply add an 'user-alias@example.com' alias to the 'user@example.com' mailbox.

    smailr add user-alias@example.com --alias user@example.com

To remove the alias again, run the rm command.

    smailr rm user-alias@example.com --alias user@example.com

You can as well specify multiple destinations for both commands separated by a comma:

    smailr add user-alias@example.com --alias user@example.com,user1@example.com

### DKIM

You can even manage RSA keys for Domain Key Identified Mail (DKIM).

To create a new key for the selector MX do:

    # smailr add example.com --dkim mx
    public-key MIGJAo<snip>AAE= # returns the public key to use

To remove the key again run:

    smailr rm example.com --dkim mx

**IMPORTANT NOTE**: You will need to setup DNS manually for DKIM to work. The
above example requires the following DNS records:

    $ORIGIN example.com
       _domainkey     IN      TXT     "t=y\; o=~\;"
    mx._domainkey     IN      TXT     "v=DKIM1\; t=y\; k=rsa\; p=MIGJAo<snip>AAE="

Further explenation:

    'mx'   matches up with your dkim_selector specified on you CLI.

    't=y'  tells remote MTAs, that you are still testing DKIM.
           Use t=n once everything works.

    'o=~'  tells everybody, that only some may gets signed.
           Use o=- if you want to sign everything.

The exim configuration assumes a selector of 'mx' by default. You can change that, so
it matches something else. Eg. the current month of the year, in case you want
to generate a new key every month.

Check the remote\_smtp transport configuration in the supplied Exim configuration file
to change that.

### Mutt

Smailr can launch mutt with the required configuration for a specific mailbox
automatically. Open mutt for the specified mailbox:

    smailr mutt user@example.com

### Verify

Smailr generates a report via the Port25 SMTP Verifier. It generates a test,
sends it to check-auth-user=eaxmple.comt@verifier.port25.com, which will in
return generate a echo message with a report about results of many SMTP
components: SPF, SenderID, DomainKeys, DKIM and Spamassassin.

To generate a message, sent from user@example.com and return the report to the
same address simply call the following command:

    smailr verify user@example.com

In case you want to generate the report for user@example.com, but receive it at
a different location add the report-to option:

    smailr verify user@example.com --report-to postmaster@ono.at

## Compatibility

Smailr was developed an tested on Debian/Squeeze and should be easily portable
to any other system.

## BUGS

For bugs or feature requests, please use the GitHub issue tracker.

https://github.com/sts/smailr/issues


## WHO

Stefan Schlesinger / sts@ono.at / @stsonoat / http://sts.ono.at

