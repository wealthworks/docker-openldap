#!/bin/bash

# ulimit -n 8192

set -e

FIRST_START_DONE="/etc/docker-openldap-first-start-done"

[ ! -e /var/lib/openldap/data ] && mkdir -p /var/lib/openldap/data

# container first start
if [ ! -e "$FIRST_START_DONE" ]; then

    if [[ -z "$SLAPD_PASSWORD" ]]; then
        echo -n >&2 "Error: Container not configured and SLAPD_PASSWORD not set. "
        echo >&2 "Did you forget to add -e SLAPD_PASSWORD=... ?"
        exit 1
    fi

    if [[ -z "$SLAPD_DOMAIN" ]]; then
        echo -n >&2 "Error: Container not configured and SLAPD_DOMAIN not set. "
        echo >&2 "Did you forget to add -e SLAPD_DOMAIN=... ?"
        exit 1
    fi

  if [ ! -d /etc/openldap/slapd.d ]; then
    mkdir /etc/openldap/slapd.d
  fi

  chown -R ldap:ldap /etc/openldap/slapd.d

  if [ -n "$SLAPD_PASSWORD" ]; then
    password_hash=`slappasswd -s "${SLAPD_PASSWORD}"`
    sed_safe_password_hash=${password_hash//\//\\\/}
    sed -i "s|rootpw.*|rootpw        ${sed_safe_password_hash}|g" /etc/openldap/slapd.conf
  fi

    SLAPD_ORGANIZATION="${SLAPD_ORGANIZATION:-${SLAPD_DOMAIN}}"

    dc_string=""
    IFS="."; declare -a dc_parts=($SLAPD_DOMAIN)
    odc=""
    for dc_part in "${dc_parts[@]}"; do
      [ -z "$dc_string" ] && odc="$dc_part"
        dc_string="$dc_string,dc=$dc_part"
    done
    base_string="${dc_string:1}"
    echo "BASE: ${base_string}"
    echo "dc: $odc"

    sed -i "s|dc=example,dc=net|$base_string|g" /etc/openldap/slapd.conf
    sed -i "s|dc=example,dc=net|$base_string|g" /etc/openldap/modules/base.ldif
    sed -i "s|dc: example|dc: $odc|g" /etc/openldap/modules/base.ldif
    sed -i "s|o: Example|o: $SLAPD_ORGANIZATION|g" /etc/openldap/modules/base.ldif
    sed -i "s/^#BASE.*/BASE  ${base_string}/g" /etc/openldap/ldap.conf

  if [ -f /etc/conf.d/slapd ]; then
    sed -i "s|#OPTS=.*|OPTS=\"-F /etc/openldap/slapd.d -h 'ldap:// ldapi://%2fvar%2frun%2fopenldap%2fslapd.sock'\"|g" /etc/conf.d/slapd
  fi

    chown -R ldap:ldap /var/lib/openldap/data
    chmod 700 /var/lib/openldap/data
  if [ -z "$(ls -A /var/lib/openldap/data)" ]; then
    echo "data directory is empty, init..."
    cp /etc/openldap/DB_CONFIG.example /var/lib/openldap/data/DB_CONFIG

    slapd -u ldap -g ldap >/dev/null 2>&1
    ldapadd -x -D "cn=admin,${base_string}" -w "${SLAPD_PASSWORD}" -f /etc/openldap/modules/base.ldif
    killall slapd
  fi

  touch $FIRST_START_DONE
else
    slapd_configs_in_env=`env | grep 'SLAPD_'`

    if [ -n "${slapd_configs_in_env:+x}" ]; then
        echo "Info: Container already configured, therefore ignoring SLAPD_xxx environment variables"
    fi
fi

echo "exec $@"
exec "$@"
