==========================================================
  OpenStack Grizzly Install Guide
==========================================================

:Version: 0.1
:Source: https://github.com/mseknibilel/OpenStack-Grizzly-Install-Guide
:Keywords: Single node OpenStack, Grizzly, Quantum, Nova, Keystone, Glance, Horizon, Cinder, LinuxBridge, KVM, Ubuntu Server 12.10 (64 bits).

Authors
==========

Copyright (C) Bilel Msekni <bilel.msekni@telecom-sudparis.eu> && Sandeep Raman <sandeepr@hp.com>

Contributors
==========

=================================================== =======================================================

 Houssem Medhioub <houssem.medhioub@it-sudparis.eu> Djamal Zeghlache <djamal.zeghlache@telecom-sudparis.eu>

=================================================== =======================================================

Wana contribute ? Read the guide, send your contribution and get your name listed ;)

Table of Contents
=================

::

  0. What is it?
  1. Requirements
  2. Preparing your node
  3. Keystone
  4. Glance
  5. Quantum
  6. Nova
  7. Cinder
  8. Horizon
  9. Licensing
  10. Contacts
  11. Acknowledgement
  12. Credits
  13. To do

0. What is it?
==============

OpenStack Grizzly Install Guide is an easy and tested way to create your own OpenStack platform. 

Version 0.1

Status: On Going Work


1. Requirements
====================

:Node Role: NICs
:Single Node: eth0 (100.10.10.51), eth1 (192.168.100.51)

**Note 1:** More guides for multi node deployments will be available soon.

**Note 2:** Always use dpkg -s <packagename> to make sure you are using grizzly packages (version : 2013.1)

**Note 3:** This is my current network architecture, you can add as many compute node as you wish.

.. image:: Image will be added Soon.

2. Preparing your node
===============

2.1. Preparing Ubuntu 12.10
-----------------

* After you install Ubuntu 12.10 Server 64bits, Go in sudo mode and don't leave it until the end of this guide::

   sudo su

* Add Grizzly repositories::

   echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main >> /etc/apt/sources.list.d/grizzly.list
   apt-get install ubuntu-cloud-keyring python-software-properties python-keyring

* Update your system::

   apt-get update
   apt-get upgrade
   apt-get dist-upgrade

2.2.Networking
------------

* Only one NIC should have an internet access::

   #For Exposing OpenStack API over the internet
   auto eth1
   iface eth1 inet static
   address 192.168.100.51
   netmask 255.255.255.0
   gateway 192.168.100.1
   dns-nameservers 8.8.8.8

   #Not internet connected(used for OpenStack management)
   auto eth0
   iface eth0 inet static
   address 100.10.10.51
   netmask 255.255.255.0

* Restart the networking service::

   service networking restart

2.3. MySQL & RabbitMQ
------------

* Install MySQL::

   apt-get install mysql-server python-mysqldb

* Configure mysql to accept all incoming requests::

   sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
   service mysql restart

* Install RabbitMQ::

   apt-get install rabbitmq-server 

* Install NTP service::

   apt-get install ntp
 
2.5. Others
-------------------

* Install other services::

   apt-get install vlan bridge-utils

* Enable IP_Forwarding::

   sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

   # To save you from rebooting, perform the following
   sysctl net.ipv4.ip_forward=1

3. Keystone
=============

* Start by the keystone packages::

   apt-get install keystone

* Verify your keystone is running::

   service keystone status

* Create a new MySQL database for keystone::

   mysql -u root -p
   CREATE DATABASE keystone;
   GRANT ALL ON keystone.* TO 'keystoneUser'@'%' IDENTIFIED BY 'keystonePass';
   quit;

* Adapt the connection attribute in the /etc/keystone/keystone.conf to the new database::

   connection = mysql://keystoneUser:keystonePass@100.10.10.51/keystone

* Modify the keystone token type in the /etc/keystone/keystone.conf::

   token_format = UUID

* Restart the identity service then synchronize the database::

   service keystone restart
   keystone-manage db_sync

* Fill up the keystone database using the two scripts available in the `Scripts folder <https://github.com/mseknibilel/OpenStack-Grizzly-Install-guide/tree/master/Keystone_Scripts>`_ of this git repository::

   #Modify the HOST_IP and HOST_IP_EXT variables before executing the scripts

   chmod +x keystone_basic.sh
   chmod +x keystone_endpoints_basic.sh

   ./keystone_basic.sh
   ./keystone_endpoints_basic.sh

* Create a simple credential file and load it so you won't be bothered later::

   nano creds

   #Paste the following:
   export OS_TENANT_NAME=admin
   export OS_USERNAME=admin
   export OS_PASSWORD=admin_pass
   export OS_AUTH_URL="http://192.168.100.51:5000/v2.0/"

   # Load it:
   source creds

* To test Keystone, we use a simple CLI command::

   keystone user-list

4. Glance
=============

* We Move now to Glance installation::

   apt-get install glance

* Verify your glance services are running::

   service glance-api status
   service glance-registry status

* Create a new MySQL database for Glance::

   mysql -u root -p
   CREATE DATABASE glance;
   GRANT ALL ON glance.* TO 'glanceUser'@'%' IDENTIFIED BY 'glancePass';
   quit;

* Update /etc/glance/glance-api-paste.ini with::

   [filter:authtoken]
   paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
   delay_auth_decision = true
   auth_host = 100.10.10.51
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = glance
   admin_password = service_pass

* Update the /etc/glance/glance-registry-paste.ini with::

   [filter:authtoken]
   paste.filter_factory = keystone.middleware.auth_token:filter_factory
   delay_auth_decision = true
   auth_host = 100.10.10.51
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = glance
   admin_password = service_pass

* Update /etc/glance/glance-api.conf with::

   sql_connection = mysql://glanceUser:glancePass@100.10.10.51/glance

* And::

   [paste_deploy]
   flavor = keystone
   
* Update the /etc/glance/glance-registry.conf with::

   sql_connection = mysql://glanceUser:glancePass@100.10.10.51/glance

* And::

   [paste_deploy]
   flavor = keystone

* Restart the glance-api and glance-registry services::

   service glance-api restart; service glance-registry restart

* Synchronize the glance database::

   glance-manage db_sync

* Restart the services again to take into account the new modifications::

   service glance-registry restart; service glance-api restart

* To test Glance, start by downloading the cirros cloud image to your node and then upload it to Glance::

   mkdir images
   cd images
   wget https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img
   
   glance image-create --name myFirstImage --is-public true --container-format bare --disk-format qcow2 < cirros-0.3.0-x86_64-disk.img

* Now list the image to see what you have just uploaded::

   glance image-list

5. Quantum
=============

* Install the Quantum components::

   apt-get install -y quantum-server quantum-plugin-linuxbridge quantum-plugin-linuxbridge-agent dnsmasq quantum-dhcp-agent quantum-l3-agent 

* Create a database::

   mysql -u root -p
   CREATE DATABASE quantum;
   GRANT ALL ON quantum.* TO 'quantumUser'@'%' IDENTIFIED BY 'quantumPass';
   quit; 

* Verify all Quantum components are running::

   cd /etc/init.d/; for i in $( ls quantum-* ); do sudo service $i status; done

* Edit the /etc/quantum/quantum.conf file::

   log_dir = /var/log/quantum
   core_plugin = quantum.plugins.linuxbridge.lb_quantum_plugin.LinuxBridgePluginV2
   lock_path = /var/lock/quantum
   
* Edit /etc/quantum/api-paste.ini ::

   [filter:authtoken]
   paste.filter_factory = keystone.middleware.auth_token:filter_factory
   auth_host = 100.10.10.51
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = quantum
   admin_password = service_pass

* Edit the LinuxBridge plugin config file /etc/quantum/plugins/linuxbridge/linuxbridge_conf.ini with:: 

   sql_connection = mysql://quantumUser:quantumPass@100.10.10.51/quantum
   physical_interface_mappings = physnet1:eth1
   tenant_network_type = vlan
   network_vlan_ranges = physnet1:1000:2999

* Create a link to the linuxbridge_conf.ini file

   ln -s /etc/quantum/plugins/linuxbridge/linuxbridge_conf.ini /etc/quantum/plugin.ini

* Edit the /etc/quantum/l3_agent.ini

   interface_driver = quantum.agent.linux.interface.BridgeInterfaceDriver
   use_namespaces = False

   # Paste this at the end of the file

   auth_url = http://100.10.10.51:35357/v2.0 
   auth_region = RegionOne
   admin_tenant_name = service
   admin_user = quantum
   admin_password = service_pass

* Edit the /etc/quantum/dhcp_agent.ini

   interface_driver = quantum.agent.linux.interface.BridgeInterfaceDriver
   use_namespaces = False

* Restart all quantum services::

   cd /etc/init.d/; for i in $( ls quantum-* ); do sudo service $i restart; done
   service dnsmasq restart

2.9. Nova
-------------------

* Start by installing nova components::

   apt-get install -y nova-api nova-cert novnc nova-consoleauth nova-scheduler nova-novncproxy

* Prepare a Mysql database for Nova::

   mysql -u root -p
   CREATE DATABASE nova;
   GRANT ALL ON nova.* TO 'novaUser'@'%' IDENTIFIED BY 'novaPass';
   quit;

* Now modify authtoken section in the /etc/nova/api-paste.ini file to this::

   [filter:authtoken]
   paste.filter_factory = keystone.middleware.auth_token:filter_factory
   auth_host = 100.10.10.51
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = nova
   admin_password = service_pass
   signing_dirname = /tmp/keystone-signing-nova

* Modify the /etc/nova/nova.conf like this::

   [DEFAULT]
   logdir=/var/log/nova
   state_path=/var/lib/nova
   lock_path=/run/lock/nova
   verbose=True
   api_paste_config=/etc/nova/api-paste.ini
   scheduler_driver=nova.scheduler.simple.SimpleScheduler
   s3_host=100.10.10.51
   ec2_host=100.10.10.51
   ec2_dmz_host=100.10.10.51
   rabbit_host=100.10.10.51
   dmz_cidr=169.254.169.254/32
   metadata_host=100.10.10.51
   metadata_listen=0.0.0.0
   sql_connection=mysql://novaUser:novaPass@100.10.10.51/nova 
   root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf

   # Auth
   auth_strategy=keystone
   keystone_ec2_url=http://100.10.10.51:5000/v2.0/ec2tokens
   # Imaging service
   glance_api_servers=100.10.10.51:9292
   image_service=nova.image.glance.GlanceImageService

   # Vnc configuration
   vnc_enabled=true
   novncproxy_base_url=http://192.168.100.51:6080/vnc_auto.html
   novncproxy_port=6080
   vncserver_proxyclient_address=192.168.100.51
   vncserver_listen=0.0.0.0 

   # Network settings
   network_api_class=nova.network.quantumv2.api.API
   quantum_url=http://100.10.10.51:9696
   quantum_auth_strategy=keystone
   quantum_admin_tenant_name=service
   quantum_admin_username=quantum
   quantum_admin_password=service_pass
   quantum_admin_auth_url=http://100.10.10.51:35357/v2.0
   libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
   linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver
   firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver

   # Compute #
   compute_driver=libvirt.LibvirtDriver

   # Cinder #
   volume_api_class=nova.volume.cinder.API
   osapi_volume_listen_port=5900

* Synchronize your database::

   nova-manage db sync

* Restart nova-* services::

   cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; done   

* Check for the smiling faces on nova-* services to confirm your installation::

   nova-manage service list

2.10. Cinder
-------------------

* Install the required packages::

   apt-get install cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms

* Configure the iscsi services::

   sed -i 's/false/true/g' /etc/default/iscsitarget

* Restart the services::
   
   service iscsitarget start
   service open-iscsi start

* Prepare a Mysql database for Cinder::

   mysql -u root -p
   CREATE DATABASE cinder;
   GRANT ALL ON cinder.* TO 'cinderUser'@'%' IDENTIFIED BY 'cinderPass';
   quit;

* Configure /etc/cinder/api-paste.ini like the following::

   [filter:authtoken]
   paste.filter_factory = keystone.middleware.auth_token:filter_factory
   service_protocol = http
   service_host = 192.168.100.51
   service_port = 5000
   auth_host = 100.10.10.51
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = cinder
   admin_password = service_pass

* Edit the /etc/cinder/cinder.conf to::

   [DEFAULT]
   rootwrap_config=/etc/cinder/rootwrap.conf
   sql_connection = mysql://cinderUser:cinderPass@100.10.10.51/cinder
   api_paste_confg = /etc/cinder/api-paste.ini
   iscsi_helper=ietadm
   volume_name_template = volume-%s
   volume_group = cinder-volumes
   verbose = True
   auth_strategy = keystone
   #osapi_volume_listen_port=5900

* Then, synchronize your database::

   cinder-manage db sync

* Finally, don't forget to create a volumegroup and name it cinder-volumes::

   dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=2G
   losetup /dev/loop2 cinder-volumes
   fdisk /dev/loop2
   #Type in the followings:
   n
   p
   1
   ENTER
   ENTER
   t
   8e
   w

* Proceed to create the physical volume then the volume group::

   pvcreate /dev/loop2
   vgcreate cinder-volumes /dev/loop2

**Note:** Beware that this volume group gets lost after a system reboot. (Click `Here <https://github.com/mseknibilel/OpenStack-Folsom-Install-guide/blob/master/Tricks%26Ideas/load_volume_group_after_system_reboot.rst>`_ to know how to load it after a reboot) 

* Restart the cinder services::

   service cinder-volume restart
   service cinder-api restart

2.11. Horizon
-------------------

* To install horizon, proceed like this ::

   apt-get install openstack-dashboard memcached


* If you don't like the OpenStack ubuntu theme, you can remove the package to disable it::

   dpkg --purge openstack-dashboard-ubuntu-theme

* Reload Apache and memcached::

   service apache2 restart; service memcached restart

You can now access your OpenStack **192.168.100.51/horizon** with credentials **admin:admin_pass**.

**Note:** A reboot might be needed for a successful login

3. Network Node
=========================

3.1. Preparing the Node
------------------

* Update your system::

   apt-get update
   apt-get upgrade
   apt-get dist-upgrade

* Install ntp service::

   apt-get install ntp

* Configure the NTP server to follow the controller node::
   
   sed -i 's/server ntp.ubuntu.com/server 100.10.10.51/g' /etc/ntp.conf
   service ntp restart  

* Install other services::

   apt-get install vlan bridge-utils

* Enable IP_Forwarding::

   sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
   # To save you from rebooting, perform the following
   sysctl net.ipv4.ip_forward=1

3.2.Networking
------------

* 3 NICs must be present::
   

   # VM internet Access
   auto eth2
   iface eth2 inet static
   address 192.168.100.52
   netmask 255.255.255.0
   gateway 192.168.100.1
   dns-nameservers 8.8.8.8
   
   # OpenStack management
   auto eth0
   iface eth0 inet static
   address 100.10.10.52
   netmask 255.255.255.0

   # VM Configuration
   auto eth1
   iface eth1 inet static
   address 100.20.20.52
   netmask 255.255.255.0


3.4. OpenVSwitch
------------------

* Install the openVSwitch::

   apt-get install -y openvswitch-switch openvswitch-datapath-dkms

* Create the bridges::

   #br-int will be used for VM integration	
   ovs-vsctl add-br br-int

   #br-eth1 will be used for VM configuration 
   ovs-vsctl add-br br-eth1
   ovs-vsctl add-port br-eth1 eth1

   #br-ex is used to make to VM accessible from the internet
   ovs-vsctl add-br br-ex
   ovs-vsctl add-port br-ex eth2

3.5. Quantum
------------------

* Install the Quantum openvswitch agent, l3 agent and dhcp agent::

   apt-get -y install quantum-plugin-openvswitch-agent quantum-dhcp-agent quantum-l3-agent

* Edit /etc/quantum/api-paste.ini::

   [filter:authtoken]
   paste.filter_factory = keystone.middleware.auth_token:filter_factory
   auth_host = 100.10.10.51
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = quantum
   admin_password = service_pass

* Edit the OVS plugin configuration file /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini with:: 

   #Under the database section
   [DATABASE]
   sql_connection = mysql://quantumUser:quantumPass@100.10.10.51/quantum

   #Under the OVS section
   [OVS]
   tenant_network_type=vlan
   network_vlan_ranges = physnet1:1:4094
   bridge_mappings = physnet1:br-eth1

* In addition, update the /etc/quantum/l3_agent.ini::

   auth_url = http://100.10.10.51:35357/v2.0
   auth_region = RegionOne
   admin_tenant_name = service
   admin_user = quantum
   admin_password = service_pass
   metadata_ip = 192.168.100.51
   metadata_port = 8775

* Make sure that your rabbitMQ IP in /etc/quantum/quantum.conf is set to the controller node::
   
   rabbit_host = 100.10.10.51

* Restart all the services::

   service quantum-plugin-openvswitch-agent restart
   service quantum-dhcp-agent restart
   service quantum-l3-agent restart

4. Compute Node
=========================

4.1. Preparing the Node
------------------

* Update your system::

   apt-get update
   apt-get upgrade
   apt-get dist-upgrade

* Install ntp service::

   apt-get install ntp

* Configure the NTP server to follow the controller node::
   
   sed -i 's/server ntp.ubuntu.com/server 100.10.10.51/g' /etc/ntp.conf
   service ntp restart  

* Install other services::

   apt-get install vlan bridge-utils

* Enable IP_Forwarding::

   sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
   # To save you from rebooting, perform the following
   sysctl net.ipv4.ip_forward=1

4.2.Networking
------------

* Perform the following::
   
   # OpenStack management
   auto eth0
   iface eth0 inet static
   address 100.10.10.53
   netmask 255.255.255.0

   # VM Configuration
   auto eth1
   iface eth1 inet static
   address 100.20.20.53
   netmask 255.255.255.0

4.3 KVM
------------------

* make sure that your hardware enables virtualization::

   apt-get install cpu-checker
   kvm-ok

* Normally you would get a good response. Now, move to install kvm and configure it::

   apt-get install -y kvm libvirt-bin pm-utils

* Edit the cgroup_device_acl array in the /etc/libvirt/qemu.conf file to::

   cgroup_device_acl = [
   "/dev/null", "/dev/full", "/dev/zero",
   "/dev/random", "/dev/urandom",
   "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
   "/dev/rtc", "/dev/hpet","/dev/net/tun"
   ]

* Delete default virtual bridge ::

   virsh net-destroy default
   virsh net-undefine default

* Enable live migration by updating /etc/libvirt/libvirtd.conf file::

   listen_tls = 0
   listen_tcp = 1
   auth_tcp = "none"

* Edit libvirtd_opts variable in /etc/init/libvirt-bin.conf file::

   env libvirtd_opts="-d -l"

* Edit /etc/default/libvirt-bin file ::

   libvirtd_opts="-d -l"

* Restart the libvirt service to load the new values::

   service libvirt-bin restart

4.4. OpenVSwitch
------------------

* Install the openVSwitch::

   apt-get install -y openvswitch-switch openvswitch-datapath-dkms

* Create the bridges::

   #br-int will be used for VM integration	
   ovs-vsctl add-br br-int

   #br-eth1 will be used for VM configuration 
   ovs-vsctl add-br br-eth1
   ovs-vsctl add-port br-eth1 eth1

4.5. Quantum
------------------

* Install the Quantum openvswitch agent::

   apt-get -y install quantum-plugin-openvswitch-agent

* Edit the OVS plugin configuration file /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini with:: 

   #Under the database section
   [DATABASE]
   sql_connection = mysql://quantumUser:quantumPass@100.10.10.51/quantum

   #Under the OVS section
   [OVS]
   tenant_network_type=vlan
   network_vlan_ranges = physnet1:1:4094
   bridge_mappings = physnet1:br-eth1

* Make sure that your rabbitMQ IP in /etc/quantum/quantum.conf is set to the controller node::
   
   rabbit_host = 100.10.10.51

* Restart all the services::

   service quantum-plugin-openvswitch-agent restart

4.6. Nova
------------------

* Install nova's required components for the compute node::

   apt-get install nova-compute-kvm

* Now modify authtoken section in the /etc/nova/api-paste.ini file to this::

   [filter:authtoken]
   paste.filter_factory = keystone.middleware.auth_token:filter_factory
   auth_host = 100.10.10.51
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = nova
   admin_password = service_pass
   signing_dirname = /tmp/keystone-signing-nova

* Edit /etc/nova/nova-compute.conf file ::
   
   [DEFAULT]
   libvirt_type=kvm
   libvirt_ovs_bridge=br-int
   libvirt_vif_type=ethernet
   libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
   libvirt_use_virtio_for_bridges=True

* Modify the /etc/nova/nova.conf like this::

   [DEFAULT]
   logdir=/var/log/nova
   state_path=/var/lib/nova
   lock_path=/run/lock/nova
   verbose=True
   api_paste_config=/etc/nova/api-paste.ini
   scheduler_driver=nova.scheduler.simple.SimpleScheduler
   s3_host=100.10.10.51
   ec2_host=100.10.10.51
   ec2_dmz_host=100.10.10.51
   rabbit_host=100.10.10.51
   dmz_cidr=169.254.169.254/32
   metadata_host=100.10.10.51
   metadata_listen=0.0.0.0
   sql_connection=mysql://novaUser:novaPass@100.10.10.51/nova
   root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf

   # Auth
   use_deprecated_auth=false
   auth_strategy=keystone
   keystone_ec2_url=http://100.10.10.51:5000/v2.0/ec2tokens
   # Imaging service
   glance_api_servers=100.10.10.51:9292
   image_service=nova.image.glance.GlanceImageService

   # Vnc configuration
   novnc_enabled=true
   novncproxy_base_url=http://192.168.100.51:6080/vnc_auto.html
   novncproxy_port=6080
   vncserver_proxyclient_address=100.10.10.53
   vncserver_listen=0.0.0.0 

   # Network settings
   network_api_class=nova.network.quantumv2.api.API
   quantum_url=http://100.10.10.51:9696
   quantum_auth_strategy=keystone
   quantum_admin_tenant_name=service
   quantum_admin_username=quantum
   quantum_admin_password=service_pass
   quantum_admin_auth_url=http://100.10.10.51:35357/v2.0
   libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
   linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver
   firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver

   # Compute #
   compute_driver=libvirt.LibvirtDriver

   # Cinder #
   volume_api_class=nova.volume.cinder.API
   osapi_volume_listen_port=5900

* Restart nova-* services::

   cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; done   

* Check for the smiling faces on nova-* services to confirm your installation::

   nova-manage service list

5. Your First VM
============

To start your first VM, we first need to create a new tenant, user, internal and external network. SSH to your controller node and perform the following.

* Create a new tenant ::

   keystone tenant-create --name project_one

* Create a new user and assign the member role to it in the new tenant (keystone role-list to get the appropriate id)::

   keystone user-create --name=user_one --pass=user_one --tenant-id $put_id_of_project_one --email=user_one@domain.com
   keystone user-role-add --tenant-id $put_id_of_project_one  --user-id $put_id_of_user_one --role-id $put_id_of_member_role

* Create a new network for the tenant::

   quantum net-create --tenant-id $put_id_of_project_one net_proj_one --provider:network_type vlan --provider:physical_network physnet1 --provider:segmentation_id 1024

* Create a new subnet inside the new tenant network::

   quantum subnet-create --tenant-id $put_id_of_project_one net_proj_one 50.50.1.0/24

* Create a router for the new tenant::

   quantum router-create --tenant-id $put_id_of_project_one router_proj_one

* Add the router to the subnet::

   quantum router-interface-add $put_router_proj_one_id_here $put_subnet_id_here

* Create your external network with the tenant id belonging to the service tenant (keystone tenant-list to get the appropriate id) ::

   quantum net-create --tenant-id $put_id_of_service_tenant ext_net --router:external=True

* Create a subnet containing your floating IPs::

   quantum subnet-create --tenant-id $put_id_of_service_tenant --allocation-pool start=192.168.100.102,end=192.168.100.126 --gateway 192.168.100.1 ext_net 192.168.100.100/24 --enable_dhcp=False

* Set the router for the external network::

   quantum router-gateway-set $put_router_proj_one_id_here $put_id_of_ext_net_here

VMs gain access to the metadata server locally present in the controller node via the external network. To create that necessary connection perform the following:

* Get the IP address of router proj one::

   quantum port-list -- --device_id <router_proj_one_id> --device_owner network:router_gateway

* Add the following route on controller node only::

   route add -net 50.50.1.0/24 gw $router_proj_one_IP

Unfortunatly, you can't use the dashboard to assign floating IPs to VMs so you need to get your hands a bit dirty to give your VM a public IP.

* Start by allocating a floating ip to the project one tenant::

   quantum floatingip-create --tenant-id $put_id_of_project_one ext_net

* pick the id of the port corresponding to your VM::

   quantum port-list

* Associate the floating IP to your VM::

   quantum floatingip-associate $put_id_floating_ip $put_id_vm_port

**This is it !**, You can now ping you VM and start administrating you OpenStack !

I Hope you enjoyed this guide, please if you have any feedbacks, don't hesitate.

6. Licensing
============

OpenStack Folsom Install Guide by Bilel Msekni is licensed under a Creative Commons Attribution 3.0 Unported License.

.. image:: http://i.imgur.com/4XWrp.png
To view a copy of this license, visit [ http://creativecommons.org/licenses/by/3.0/deed.en_US ].

7. Contacts
===========

Bilel Msekni: bilel.msekni@telecom-sudparis.eu

8. Acknowledgment
=================

This work has been supported by:

* CompatibleOne Project (French FUI project) [http://compatibleone.org/]
* Easi-Clouds (ITEA2 project) [http://easi-clouds.eu/]

9. Credits
=================

This work has been based on:

* Emilien Macchi's Folsom guide [https://github.com/EmilienM/openstack-folsom-guide]
* OpenStack Documentation [http://docs.openstack.org/trunk/openstack-compute/install/apt/content/]
* OpenStack Quantum Install [http://docs.openstack.org/trunk/openstack-network/admin/content/ch_install.html]

10. To do
=======

This guide is just a startup. Your suggestions are always welcomed.

Some of this guide's needs might be:

* Define more Quantum configurations to cover all usecases possible see `here <http://docs.openstack.org/trunk/openstack-network/admin/content/use_cases.html>`_. 




