[![CI workflow](https://img.shields.io/github/workflow/status/dns3l/auth/main?label=ci&logo=github)](https://github.com/dns3l/auth/actions/workflows/main.yml)
[![GitHub release](https://img.shields.io/github/release/dns3l/auth.svg&logo=github)](https://github.com/dns3l/auth/releases/latest)
[![Semantic Release](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)
![License](https://img.shields.io/github/license/dns3l/auth)

## [Dex][1] OIDC provider backend for DNS3L

`docker pull ghcr.io/dns3l/auth`

[1]: https://dexidp.io/

### Configuration

| variable | note | default |
| --- | --- | --- |
| ENVIRONMENT | `production` or other deployments | |
| DEX_URL | published Dex endpoint | `http://localhost:5556/auth` |
| DNS3L_URL | published DNS3L endpoint | `http://localhost:3000` |
| HELP_URL | provide help regarding auth | `https://github.com/dns3l/dns3l` |
| DNS3L_USER | local account(s) UID | `certbot` |
| DNS3L_USERNAME | local account username | `CertBOT` |
| DNS3L_USERMAIL | local account e-mail | `certbot@example.com` |
| DNS3L_PASS | local account(s) password | random |
| DNS3L_CLI_SECRET | CLI shared secret | random |
| LDAP_CONNECTOR_NAME | UI display name | `LDAP` |
| LDAP_CONNECTOR_HOST | AD/LDAP server | `localhost:636` |
| LDAP_CONNECTOR_PROMPT | UI prompt | `LDAP Username` |
| LDAP_TLS_VERIFY | enforce TLS validation | `no` |
| LDAP_STARTTLS | use `STARTTLS` | `no` |
| LDAP_BindDN | DN to bind | |
| LDAP_BindPW | password for bind DN | |
| LDAP_USER_BASE | [ldap connector][2] | `ou=users,dc=localhost` |
| LDAP_USER_FILTER | [ldap connector][2] | `(objectClass=*)` |
| LDAP_GROUP_BASE | [ldap connector][2] | `ou=groups,dc=localhost` |
| LDAP_GROUP_FILTER | [ldap connector][2] | `(objectClass=*)` |
| LDAP_USER_ID_ATTR | [ldap connector][2] | `DN` |
| LDAP_USER_UID_ATTR | [ldap connector][2] | `sAMAccountName` |
| LDAP_USER_MAIL_ATTR | [ldap connector][2] | `mail` |
| LDAP_USER_NAME_ATTR | [ldap connector][2] | `displayName` |
| LDAP_GROUP_NAME_ATTR | [ldap connector][2] | `cn` |
| LDAP_GROUP_USER_ATTR | [ldap connector][2] | `DN` |
| LDAP_GROUP_MEMBER_ATTR | [ldap connector][2] | `member` |

[2]: https://dexidp.io/docs/connectors/ldap/

If `ENVIRONMENT` is `production` and `LDAP_BindDN`, `LDAP_BindPW` are set the LDAP connector is configured only.
