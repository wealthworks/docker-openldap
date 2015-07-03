FROM alpine:3.2
MAINTAINER Eagle Liut <eagle@dantin.me>

RUN apk add --update openldap openldap-back-bdb openldap-clients && rm -rf /var/cache/apk/*

ADD slapd.conf /etc/openldap/slapd.conf

ADD entrypoint.sh /ep.sh

ENTRYPOINT ["/ep.sh"]

VOLUME ["/var/lib/openldap"]

EXPOSE 389

CMD ["slapd", "-d", "32768", "-u", "ldap", "-g", "ldap"]
