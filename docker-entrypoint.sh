#!/bin/bash
set -e

umask 0022

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
#  (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#   "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
function file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

# envs=(
#   XYZ_API_TOKEN
# )
# haveConfig=
# for e in "${envs[@]}"; do
#   file_env "$e"
#   if [ -z "$haveConfig" ] && [ -n "${!e}" ]; then
#     haveConfig=1
#   fi
# done

# return true if specified directory is empty
function directory_empty() {
  [ -n "$(find "${1}"/ -prune -empty)" ]
}

function random_token() {
  tr -cd '[:alnum:]' </dev/urandom | fold -w32 | head -n1
}

SERVICE_TIMEOUT=${SERVICE_TIMEOUT:-300s} # wait for dependencies

echo Running: "$@"

export DEX_URL=${DEX_URL:-"http://localhost:5556/auth"}
export DNS3L_URL=${DNS3L_URL:-"http://localhost:3000"}
export HELP_URL=${HELP_URL:-"https://github.com/dns3l/dns3l"}

export LDAP_CONNECTOR_ID=${LDAP_CONNECTOR_ID:-"ldap"}
export LDAP_CONNECTOR_NAME=${LDAP_CONNECTOR_NAME:-"LDAP"}
export LDAP_CONNECTOR_HOST=${LDAP_CONNECTOR_HOST:-"localhost:636"}
export LDAP_CONNECTOR_PROMPT=${LDAP_CONNECTOR_PROMPT:-"LDAP Username"}

export LDAP_TLS_VERIFY=${LDAP_TLS_VERIFY:no}
export LDAP_TLS_VERIFY=${LDAP_TLS_VERIFY,,}
if [[ ${LDAP_TLS_VERIFY} != "yes" ]]; then
  export LDAP_TLS_VERIFY=true
else
  export LDAP_TLS_VERIFY=false
fi
export LDAP_STARTTLS=${LDAP_STARTTLS:-no}
export LDAP_STARTTLS=${LDAP_STARTTLS,,}
if [[ ${LDAP_STARTTLS} != "yes" ]]; then
  export LDAP_STARTTLS=false
fi
if [[ ${LDAP_STARTTLS} == "yes" ]]; then
  export LDAP_STARTTLS=true
  export LDAP_CONNECTOR_HOST=`echo ${LDAP_CONNECTOR_HOST} | sed -e 's/:636$/:389/'`
fi
export LDAP_USER_BASE=${LDAP_USER_BASE:-"ou=users,dc=localhost"}
export LDAP_USER_FILTER=${LDAP_USER_FILTER:-"(objectClass=*)"}

export LDAP_GROUP_BASE=${LDAP_GROUP_BASE:-"ou=groups,dc=localhost"}
export LDAP_GROUP_FILTER=${LDAP_GROUP_FILTER:-"(objectClass=*)"}

export LDAP_USER_ID_ATTR=${LDAP_USER_ID_ATTR:-"DN"}
export LDAP_USER_UID_ATTR=${LDAP_USER_UID_ATTR:-"sAMAccountName"}
export LDAP_USER_MAIL_ATTR=${LDAP_USER_MAIL_ATTR:-"mail"}
export LDAP_USER_NAME_ATTR=${LDAP_USER_NAME_ATTR:-"displayName"}

export LDAP_GROUP_NAME_ATTR=${LDAP_GROUP_NAME_ATTR:-"cn"}
export LDAP_GROUP_USER_ATTR=${LDAP_GROUP_USER_ATTR:-"DN"}
export LDAP_GROUP_MEMBER_ATTR=${LDAP_GROUP_MEMBER_ATTR:-"member"}

export ldap=false
if [[ -n $LDAP_BindDN && -n $LDAP_BindPW ]]; then
  export ldap=true
fi
export production=false
if [[ ${ENVIRONMENT,,} == "production" ]]; then
  export production=true
fi

export DNS3L_USER=${DNS3L_USER:-certbot}
export DNS3L_USERNAME=${DNS3L_USERNAME:-CertBOT}
export DNS3L_USERMAIL=${DNS3L_USERMAIL:-"certbot@example.com"}
export DNS3L_USER_UUID=`uuidgen -r`

P=$(random_token)
export DNS3L_PASS=${DNS3L_PASS:-$P}
export DNS3L_PASS_HASH=`echo ${DNS3L_PASS} | htpasswd -n -B -C 10 -i ${DNS3L_USER} | cut -d: -f2`
P=$(random_token)
export DNS3L_CLI_SECRET=${DNS3L_CLI_SECRET:-$P}
P=$(random_token)
export DNS3L_API_SECRET=${DNS3L_API_SECRET:-$P}

# Avoid destroying bootstrapping by simple start/stop
if [[ ! -e ${DEXPATH}/.bootstrapped ]]; then
  ### list none idempotent code blocks, here...

  touch ${DEXPATH}/.bootstrapped
fi

echo Generate selfsigned cert/key pair
openssl req -x509 -batch -newkey rsa:4096 -sha256 -days 90 -nodes \
            -keyout ${DEXPATH}/tls.key -out ${DEXPATH}/tls.crt \
            -subj "/CN=dex" \
            -addext "keyUsage=critical,digitalSignature,keyAgreement" \
            -addext "extendedKeyUsage=serverAuth" \
            -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" 2>/dev/null

if [ -r /etc/dex.conf.yml -a -s /etc/dex.conf.yml ]; then
  ln -fs /etc/dex.conf.yml ${DEXPATH}/config.yaml
else
  /dckrz -template /etc/dex/config.yaml.tmpl:${DEXPATH}/config.yaml
fi

if [[ `basename ${1}` == "dex" ]]; then # prod
    exec "$@" </dev/null #>/dev/null 2>&1
else # dev
    dex serve ${DEXPATH}/config.yaml || true 2>&1 &
fi

# fallthrough...
exec "$@"
