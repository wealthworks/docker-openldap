FROM alpine:3.2
MAINTAINER Eagle Liut <eagle@dantin.me>

RUN apk add --update bash openldap openldap-back-bdb openldap-back-hdb openldap-clients && rm -rf /var/cache/apk/*

ADD slapd.conf /etc/openldap/slapd.conf
ENV LDAPCONF /etc/openldap/slapd.conf

ADD modules /etc/openldap/modules
ADD entrypoint.sh /ep.sh

ENTRYPOINT ["/ep.sh"]

VOLUME ["/var/lib/openldap"]

EXPOSE 389

# CMD ["/ep.sh"]
CMD ["slapd", "-u", "ldap", "-g", "ldap", "-d", "32768"]
