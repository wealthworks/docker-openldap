#!/bin/sh

# ulimit -n 8192

set -e

FIRST_START_DONE="/etc/docker-openldap-first-start-done"

# container first start
if [ ! -e "$FIRST_START_DONE" ]; then

    if [[ -z "$SLAPD_PASSWORD" ]]; then
        echo -n >&2 "Error: Container not configured and SLAPD_PASSWORD not set. "
        echo >&2 "Did you forget to add -e SLAPD_PASSWORD=... ?"
        exit 1
    fi

    if [[ -z "$SLAPD_BASE_DN" ]]; then
        echo -n >&2 "Error: Container not configured and SLAPD_BASE_DN not set. "
        echo >&2 "Did you forget to add -e SLAPD_BASE_DN=... ?"
        exit 1
    fi

  if [[ -n "$SLAPD_BASE_DN" ]]; then
    sed -i "s|dc=example,dc=net|$SLAPD_BASE_DN|g" /etc/openldap/slapd.conf
    sed -i "s/^#BASE.*/${SLAPD_BASE_DN}/g" /etc/openldap/ldap.conf
  fi

  if [[ -n "$SLAPD_PASSWORD" ]]; then
    sed -i "s|rootpw.*|rootpw        $SLAPD_PASSWORD|g" /etc/openldap/slapd.conf
  fi

  if [[ ! -d /var/lib/openldap/data ]]; then
    mkdir -p /var/lib/openldap/data
    # chown -R ldap:ldap /var/lib/openldap/data
    cp /var/lib/openldap/openldap-data/DB_CONFIG.example /var/lib/openldap/data/DB_CONFIG
  fi

  chown -R ldap:ldap /var/lib/openldap/

else
    slapd_configs_in_env=`env | grep 'SLAPD_'`

    if [ -n "${slapd_configs_in_env:+x}" ]; then
        echo "Info: Container already configured, therefore ignoring SLAPD_xxx environment variables"
    fi
fi

exec "$@"
