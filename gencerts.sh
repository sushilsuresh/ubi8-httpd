!/bin/bash

BASE_DOMAIN="example.com"
DEFAULT_INGRESS_DOMAIN="apps.example.com"
DMZ_INGRESS_DOMAIN="dmz.example.com"
API_INGRESS_DOMAIN="www.example.com"
CA_SERIAL=$(echo ${BASE_DOMAIN} | cut -f1 -d'.')
SAN_CERT_CONFIG="api-san-ssl.conf"


cat <<EOF > ${SAN_CERT_CONFIG}
[ req ]
default_bits       = 4096
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[ dn ]
C=US
ST=North Carolina
L=Raleigh
O=RedHat
OU=Consulting
CN=www.${BASE_DOMAIN}

[ req_ext ]
subjectAltName = @alt_names

[alt_names]
DNS.1   = api.${BASE_DOMAIN}
EOF


openssl genrsa -out ${BASE_DOMAIN}-ca.key 2048
openssl req -x509 -new \
                  -key ${BASE_DOMAIN}-ca.key \
                  -out ${BASE_DOMAIN}-ca.crt \
                  -subj "/C=US/ST=NC/L=Raleigh/O=RedHat/OU=Consulting/CN=$BASE_DOMAIN" \
                  -days 1825


# Generate tls certs for the Default ingress controller
openssl genrsa -out ${DEFAULT_INGRESS_DOMAIN}.key 2048
openssl req -new \
            -key ${DEFAULT_INGRESS_DOMAIN}.key \
            -out ${DEFAULT_INGRESS_DOMAIN}.csr \
            -subj "/C=US/ST=NC/L=Raleigh/O=RedHat/OU=Consulting/CN=*.${DEFAULT_INGRESS_DOMAIN}"
openssl x509 -req -in ${DEFAULT_INGRESS_DOMAIN}.csr \
                  -CA ${BASE_DOMAIN}-ca.crt \
                  -CAkey ${BASE_DOMAIN}-ca.key \
                  -CAcreateserial \
                  -out ${DEFAULT_INGRESS_DOMAIN}.crt \
                  -days 1825

# Generate tls certs for the DMZ ingress controller
openssl genrsa -out ${DMZ_INGRESS_DOMAIN}.key 2048
openssl req -new \
            -key ${DMZ_INGRESS_DOMAIN}.key \
            -out ${DMZ_INGRESS_DOMAIN}.csr \
            -subj "/C=US/ST=NC/L=Raleigh/O=RedHat/OU=Consulting/CN=*.${DMZ_INGRESS_DOMAIN}"
openssl x509 -req -in ${DMZ_INGRESS_DOMAIN}.csr \
             -CA ${BASE_DOMAIN}-ca.crt \
             -CAkey ${BASE_DOMAIN}-ca.key \
             -CAserial ${CA_SERIAL}.srl \
             -out ${DMZ_INGRESS_DOMAIN}.crt \
             -days 1825
# since the previous cert generationcommand creates a CA serial file because we said -CAcreateserial,
# this time around we just need to use it. Hence -CAserial ${CA_SERIAL}.srl


# Generate tls certs for the API endpoint
openssl genrsa -out ${API_INGRESS_DOMAIN}.key 2048
openssl req -new \
            -key ${API_INGRESS_DOMAIN}.key \
            -out ${API_INGRESS_DOMAIN}.csr \
            -config ${SAN_CERT_CONFIG}
openssl x509 -req -in ${API_INGRESS_DOMAIN}.csr \
                  -CA ${BASE_DOMAIN}-ca.crt \
                  -CAkey ${BASE_DOMAIN}-ca.key \
                  -CAserial ${CA_SERIAL}.srl \
                  -out ${API_INGRESS_DOMAIN}.crt \
                  -extensions req_ext \
                  -extfile ${SAN_CERT_CONFIG} \
                  -days 1825

