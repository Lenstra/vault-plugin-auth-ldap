module github.com/lenstra/vault-plugin-auth-ldap

go 1.12

require (
	github.com/go-ldap/ldap/v3 v3.4.1
	github.com/go-test/deep v1.0.8
	github.com/hashicorp/go-hclog v1.1.0
	github.com/hashicorp/go-secure-stdlib/password v0.1.1
	github.com/hashicorp/go-secure-stdlib/strutil v0.1.2
	github.com/hashicorp/vault v1.10.3
	github.com/hashicorp/vault/api v1.4.1
	github.com/hashicorp/vault/sdk v0.4.2-0.20220429220057-bdb59a36e632
	github.com/mitchellh/mapstructure v1.4.3
)
