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

echo Running: "$@"

DEX_URL=${DEX_URL:-"http://localhost:5556/auth"}
DNS3L_URL=${DNS3L_URL:-"http://localhost:3000"}
HELP_URL=${HELP_URL:-"https://github.com/iaean/dns3l"}

LDAP_CONNECTOR_ID=${LDAP_CONNECTOR_ID:-"ldap"}
LDAP_CONNECTOR_NAME=${LDAP_CONNECTOR_NAME:-"LDAP"}
LDAP_CONNECTOR_HOST=${LDAP_CONNECTOR_HOST:-"localhost:636"}
LDAP_CONNECTOR_PROMPT=${LDAP_CONNECTOR_PROMPT:-"LDAP Username"}

LDAP_TLS_VERIFY=${LDAP_TLS_VERIFY:no}
LDAP_TLS_VERIFY=${LDAP_TLS_VERIFY,,}
if [[ ${LDAP_TLS_VERIFY} != "yes" ]]; then
  LDAP_TLS_VERIFY=true
else
  LDAP_TLS_VERIFY=false
fi
LDAP_STARTTLS=${LDAP_STARTTLS:-no}
LDAP_STARTTLS=${LDAP_STARTTLS,,}
if [[ ${LDAP_STARTTLS} != "yes" ]]; then
  LDAP_STARTTLS=false
fi
if [[ ${LDAP_STARTTLS} == "yes" ]]; then
  LDAP_STARTTLS=true
  LDAP_CONNECTOR_HOST=`echo ${LDAP_CONNECTOR_HOST} | sed -e 's/:636$/:389/'`
fi
LDAP_USER_BASE=${LDAP_USER_BASE:-"ou=users,dc=localhost"}
LDAP_USER_FILTER=${LDAP_USER_FILTER:-"(objectClass=*)"}

LDAP_GROUP_BASE=${LDAP_GROUP_BASE:-"ou=groups,dc=localhost"}
LDAP_GROUP_FILTER=${LDAP_GROUP_FILTER:-"(objectClass=*)"}

LDAP_USER_ID_ATTR=${LDAP_USER_ID_ATTR:-"DN"}
LDAP_USER_UID_ATTR=${LDAP_USER_UID_ATTR:-"sAMAccountName"}
LDAP_USER_MAIL_ATTR=${LDAP_USER_MAIL_ATTR:-"mail"}
LDAP_USER_NAME_ATTR=${LDAP_USER_NAME_ATTR:-"displayName"}

LDAP_GROUP_NAME_ATTR=${LDAP_GROUP_NAME_ATTR:-"cn"}
LDAP_GROUP_USER_ATTR=${LDAP_GROUP_USER_ATTR:-"DN"}
LDAP_GROUP_MEMBER_ATTR=${LDAP_GROUP_MEMBER_ATTR:-"member"}

ldap=false
if [[ -n $LDAP_BindDN && -n $LDAP_BindPW ]]; then
  ldap=true
fi
production=false
if [[ ${ENVIRONMENT,,} == "production" ]]; then
  production=true
fi

DNS3L_USER=${DNS3L_USER:-certbot}
DNS3L_USERNAME=${DNS3L_USERNAME:-CertBOT}
DNS3L_USERMAIL=${DNS3L_USERMAIL:-"certbot@example.com"}
DNS3L_USER_UUID=`uuidgen -r`

P=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w32 | head -n1)
DNS3L_PASS=${DNS3L_PASS:-$P}
DNS3L_PASS_HASH=`echo ${DNS3L_PASS} | htpasswd -n -B -C 10 -i ${DNS3L_USER} | cut -d: -f2`
P=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w32 | head -n1)
DNS3L_CLI_SECRET=${DNS3L_CLI_SECRET:-$P}

. /mo

# Avoid destroying bootstrapping by simple start/stop
if [[ ! -e ${DEXPATH}/.bootstrapped ]]; then
  ### list none idempotent code blocks, here...

  touch ${DEXPATH}/.bootstrapped
fi

cat /etc/dex/config.yaml.mustache | mo -e > ${DEXPATH}/config.yaml

if [[ `basename ${1}` == "dex" ]]; then # prod
    exec "$@" </dev/null #>/dev/null 2>&1
else # dev
    dex serve ${DEXPATH}/config.yaml || true 2>&1 &
fi

# fallthrough...
exec "$@"
