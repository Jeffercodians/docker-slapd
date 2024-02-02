include		"${SLAPD_CONFIG_DIR}/schema/core.schema"

pidfile		"${SLAPD_RUN_DIR}/slapd.pid"

modulepath	"${SLAPD_INSTALL_DIR}/libexec/openldap"
moduleload	back_mdb.la


database config


database	mdb
maxsize		1073741824
suffix		"${SLAPD_LDAP_SUFFIX}"
rootdn		"cn=Manager,${SLAPD_LDAP_SUFFIX}"
rootpw		secret
directory	"${SLAPD_DATA_DIR}"
index	objectClass	eq


database monitor
