#!/bin/sh
#
# Keystone basic configuration 

# Mainly inspired by https://github.com/openstack/keystone/blob/master/tools/sample_data.sh

# Modified by Bilel Msekni / Institut Telecom
#
# Support: openstack@lists.launchpad.net
# License: Apache Software License (ASL) 2.0
#
HOST_IP=10.10.10.51
ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin_pass}
SERVICE_PASSWORD=${SERVICE_PASSWORD:-service_pass}
export SERVICE_TOKEN="ADMIN"
export SERVICE_ENDPOINT="http://${HOST_IP}:35357/v2.0"
SERVICE_TENANT_NAME=${SERVICE_TENANT_NAME:-service}

get_id () {
    echo `$@ | awk '/ id / { print $4 }'`
}

# Tenants
ADMIN_TENANT=$(get_id keystone tenant-create --name=admin)
SERVICE_TENANT=$(get_id keystone tenant-create --name=$SERVICE_TENANT_NAME)


# Users
ADMIN_USER=$(get_id keystone user-create --name=admin --pass="$ADMIN_PASSWORD" --email=admin@domain.com)


# Roles
ADMIN_ROLE=$(get_id keystone role-create --name=admin)
KEYSTONEADMIN_ROLE=$(get_id keystone role-create --name=KeystoneAdmin)
KEYSTONESERVICE_ROLE=$(get_id keystone role-create --name=KeystoneServiceAdmin)

# Add Roles to Users in Tenants
keystone user-role-add --user $ADMIN_USER --role $ADMIN_ROLE --tenant_id $ADMIN_TENANT
keystone user-role-add --user $ADMIN_USER --role $KEYSTONEADMIN_ROLE --tenant_id $ADMIN_TENANT
keystone user-role-add --user $ADMIN_USER --role $KEYSTONESERVICE_ROLE --tenant_id $ADMIN_TENANT

# The Member role is used by Horizon and Swift
MEMBER_ROLE=$(get_id keystone role-create --name=Member)

# Configure service users/roles
NOVA_USER=$(get_id keystone user-create --name=nova --pass="$SERVICE_PASSWORD" --tenant_id $SERVICE_TENANT --email=nova@domain.com)
keystone user-role-add --tenant_id $SERVICE_TENANT --user $NOVA_USER --role $ADMIN_ROLE

GLANCE_USER=$(get_id keystone user-create --name=glance --pass="$SERVICE_PASSWORD" --tenant_id $SERVICE_TENANT --email=glance@domain.com)
keystone user-role-add --tenant_id $SERVICE_TENANT --user $GLANCE_USER --role $ADMIN_ROLE

QUANTUM_USER=$(get_id keystone user-create --name=quantum --pass="$SERVICE_PASSWORD" --tenant_id $SERVICE_TENANT --email=quantum@domain.com)
keystone user-role-add --tenant_id $SERVICE_TENANT --user $QUANTUM_USER --role $ADMIN_ROLE

CINDER_USER=$(get_id keystone user-create --name=cinder --pass="$SERVICE_PASSWORD" --tenant_id $SERVICE_TENANT --email=cinder@domain.com)
keystone user-role-add --tenant_id $SERVICE_TENANT --user $CINDER_USER --role $ADMIN_ROLE
