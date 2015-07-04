docker-openldap
===============

Usage
-----

The most simple form would be to start the application like so (however this is
not the recommended way - see below):

    $ docker run -d -p 389:389 -e SLAPD_PASSWORD="mypassword" -e SLAPD_DOMAIN="dc=example,dc=net" lcgc/openldap

To get the full potential this image offers, one should first create a data-only
container (see "Data persistence" below), start the OpenLDAP daemon as follows:

    docker run -d -name openldap --volumes-from your-data-container lcgc/openldap

An application talking to OpenLDAP should then `--link` the container:

    docker run -d --link openldap:openldap image-using-openldap

The name after the colon in the `--link` section is the hostname where the
OpenLDAP daemon is listening to (the port is the default port `389`).

Configuration (environment variables)
-------------------------------------

For the first run, one has to set at least two environment variables. The first

    SLAPD_PASSWORD

sets the password for the `admin` user.

The second

    SLAPD_DOMAIN

sets the DC (Domain component) parts. E.g. if one sets it to `ldap.example.org`,
the generated base DC parts would be `...,dc=ldap,dc=example,dc=org`.


Data persistence
----------------

The image exposes two directories (`VOLUME ["/var/lib/openldap"]`).
The first holds the "static" configurationm while the second holds the actual
database. Please make sure that these two directories are saved (in a data-only
container or alike) in order to make sure that everything is restored after a
restart of the container.
