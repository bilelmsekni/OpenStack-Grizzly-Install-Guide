==========================================================
  OpenStack Grizzly-Nicira NVP Install Guide
==========================================================

:Version: 1.0.0
:Source: https://github.com/rflax/OpenStack-Grizzly-Install-Guide
:Keywords: Single node OpenStack, Grizzly, Quantum, Nova, Keystone, Glance, Horizon, Cinder, Nicira, NVP, KVM, Ubuntu Server 12.04 (64 bits).


Table of Contents
=================

::

  0. Description
  1. Requirements
  2. Preparing your node
  3. Keystone
  4. Glance
  5. Quantum
  6. Nova
  7. Cinder
  8. Horizon
  9. Creating VMs
 10. Add an additional Compute Node

0. Description
==============

This OpenStack Grizzly Install Guide is an easy and tested way to create your own OpenStack platform for use with Nicira NVP. 


1. Requirements
====================

:Node Role: NICs
:Single Node: eth0 (10.127.1.200), eth1 (10.10.1.200)

**Note** Always use dpkg -s <packagename> to make sure you are using grizzly packages (version : 2013.1)

2. Preparing your node
===============

2.1. Preparing Ubuntu
-----------------

* After you install Ubuntu 12.04 Server 64bits, Go in sudo mode and don't leave it until the end of this guide::

   sudo su

* Add Grizzly repositories::

   apt-get install ubuntu-cloud-keyring python-software-properties software-properties-common python-keyring
   echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main >> /etc/apt/sources.list.d/grizzly.list

* Update your system::

   apt-get update
   apt-get upgrade
   apt-get dist-upgrade

2.2.Networking
------------

* Only one NIC should have an internet access (/etc/network/interfaces) :: 

   #For Exposing OpenStack API over the internet - management network
   auto eth1
   iface eth1 inet static
   address 10.127.1.200
   netmask 255.255.255.0
   gateway 10.127.1.1
   dns-nameservers 8.8.8.8

   #Not internet connected(used for OpenStack management) - data network
   auto eth0
   iface eth0 inet static
   address 10.10.1.200
   netmask 255.255.255.0

* Restart the networking service::

   service networking restart

* Install Open vSwitch (Use the Nicira version from the nicira.com support web site)::

   download nvp-ovs-<version_string>-ubuntu_precise_amd64.gz
   tar -xzvf nvp-ovs*.gz
   apt-get install -y dkms libssl0.9.8
   dpkg -i openvswitch-*.deb
   dpkg -i nicira-ovs-hypervisor-node*.deb
   ovs-integrate nics-to-bridge eth0 eth1
  
   # Add the following to /etc/rc.local before 'exit 0'
   ifconfig eth0 0.0.0.0 up
   ifconfig breth0 10.127.1.200 netmask 255.255.255.0 up

   ifconfig eth1 0.0.0.0 up
   ifconfig breth1 10.10.1.200 netmask 255.255.255.0 up

   route add default gw 10.127.1.1

* Verify Open vSwitch configuration to this point::

   ovs-vsctl show

   # you should have something like this

   Bridge "breth1"
      fail_mode: standalone
      Port "eth1"
          Interface "eth1"
      Port "breth1"
          Interface "breth1"
              type: internal
   Bridge "breth0"
      fail_mode: standalone
      Port "breth0"
          Interface "breth0"
              type: internal
      Port "eth0"
          Interface "eth0"
   Bridge br-int
      fail_mode: secure
      Port br-int
          Interface br-int
              type: internal

* Register this Hypervisor Transport Node (Open vSwitch) with Nicira NVP::

   # Set the open vswitch manager address
   ovs-vsctl set-manager ssl:<IP Address of one of your Nicira NVP controllers>

   # Get the client pki cert
   cat /etc/openvswitch/ovsclient-cert.pem

   # Copy the contents of the output including the BEGIN and END CERTIFICATE lines and be prepared to paste this into NVP manager
   # In NVP Manager add a new Hypervisor, follow the prompts and paste the client certificate when prompted
   # Please review the NVP User Guide for details on adding Hypervisor transport nodes to NVP for more information on this step

* Reboot the server and make sure you still have network connectivity::

   # an ifconfig should reveal eth0, eth1 interfaces that do not have IP addresses as well as breth0 and breth1 interfaces that do have IP addresses
   # you should be able to ping your upstream gateway 10.127.1.1, etc.

2.3. MySQL & RabbitMQ
------------

* Install MySQL and specify a password for the root user::

   apt-get install -y mysql-server python-mysqldb

* Configure mysql to accept all incoming requests::

   sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
   service mysql restart

* Install RabbitMQ::

   apt-get install -y rabbitmq-server 

* Install NTP service::

   apt-get install -y ntp
 
2.5. Others
-------------------

* Install other services::

   apt-get install -y vlan bridge-utils

* Enable IP_Forwarding::

   sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

   # To save you from rebooting, perform the following
   sysctl net.ipv4.ip_forward=1

3. Keystone
=============

* Start by the keystone packages::

   apt-get install -y keystone

* Verify your keystone is running::

   service keystone status

* Create a new MySQL database for keystone::

   mysql -u root -p
   CREATE DATABASE keystone;
   GRANT ALL ON keystone.* TO 'keystoneUser'@'%' IDENTIFIED BY 'keystonePass';
   quit;

* Adapt the connection attribute in the /etc/keystone/keystone.conf to the new database::

   connection = mysql://keystoneUser:keystonePass@10.127.1.200/keystone

* Restart the identity service then synchronize the database::

   service keystone restart
   keystone-manage db_sync

* Fill up the keystone database using the two scripts available in the `Scripts folder <https://github.com/mseknibilel/OpenStack-Grizzly-Install-Guide/tree/master/KeystoneScripts>`_ of this git repository::

   #Modify the HOST_IP and HOST_IP_EXT variables before executing the scripts

   wget https://raw.github.com/mseknibilel/OpenStack-Grizzly-Install-Guide/master/KeystoneScripts/keystone_basic.sh
   wget https://raw.github.com/mseknibilel/OpenStack-Grizzly-Install-Guide/master/KeystoneScripts/keystone_endpoints_basic.sh

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
   export OS_AUTH_URL="http://10.127.1.200:5000/v2.0/"

   # Load it:
   source creds

* To test Keystone, we use a simple CLI command::

   keystone user-list

4. Glance
=============

* We Move now to Glance installation::

   apt-get install -y glance

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
   auth_host = 10.127.1.200
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = glance
   admin_password = service_pass

* Update the /etc/glance/glance-registry-paste.ini with::

   [filter:authtoken]
   paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
   auth_host = 10.127.1.200
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = glance
   admin_password = service_pass

* Update /etc/glance/glance-api.conf with::

   sql_connection = mysql://glanceUser:glancePass@10.127.1.200/glance

* And::

   [paste_deploy]
   flavor = keystone
   
* Update the /etc/glance/glance-registry.conf with::

   sql_connection = mysql://glanceUser:glancePass@10.127.1.200/glance

* And::

   [paste_deploy]
   flavor = keystone

* Restart the glance-api and glance-registry services::

   service glance-api restart; service glance-registry restart

* Synchronize the glance database::

   glance-manage db_sync

* Restart the services again to take into account the new modifications::

   service glance-registry restart; service glance-api restart

* To test Glance, upload the cirros cloud image directly from the internet::

   glance image-create --name myFirstImage --is-public true --container-format bare --disk-format qcow2 --location https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img

* Now list the image to see what you have just uploaded::

   glance image-list

5. Quantum
=============

* Install the Quantum components::

   apt-get install -y quantum-server quantum-plugin-nicira dnsmasq quantum-dhcp-agent 

* Create a database::

   mysql -u root -p
   CREATE DATABASE quantum;
   GRANT ALL ON quantum.* TO 'quantumUser'@'%' IDENTIFIED BY 'quantumPass';
   quit; 

* Verify all Quantum components are running::

   cd /etc/init.d/; for i in $( ls quantum-* ); do sudo service $i status; done

* Edit the /etc/quantum/quantum.conf file::

   # under [DEFAULT] section
   core_plugin = quantum.plugins.nicira.nicira_nvp_plugin.QuantumPlugin.NvpPluginV2

   # under [keystone_authtoken] section
   [keystone_authtoken]
   auth_host = 10.127.1.200
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = quantum
   admin_password = service_pass
   signing_dir = /var/lib/quantum/keystone-signing
   
* Edit /etc/quantum/api-paste.ini ::

   [filter:authtoken]
   paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
   auth_host = 10.127.1.200
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = quantum
   admin_password = service_pass

* Edit the NVP plugin config file /etc/quantum/plugins/nicira/nvp.ini with:: 

   # under [DATABASE] section  
   sql_connection = mysql://quantumUser:quantumPass@10.10.1.200/quantum
   # under [NVP] section
   enable_metadata_access_network = True
   # under [CLUSTER] section
   #  the name can be anything you want it just distinguishes multiple cluster definitions
   [CLUSTER:<name of your instance>]
   default_tz_uuid = <UUID of the Transport Zone you want to use from your NVP instance>
   default_l3_gw_service_uuid = <UUID of the default L3 Gateway Service from your NVP instance>
   default_l2_gw_service_uuid = <UUID of the default L2 Gateway Service> # Optional if not using this feature
   nvp_controller_connection=<IP Address of Controller 1 from your NVP instance>:443:admin:admin:30:10:2:2
   nvp_controller_connection=<IP Address of Controller 2 from your NVP instance>:443:admin:admin:30:10:2:2
   nvp_controller_connection=<IP Address of Controller 3 from your NVP instance>:443:admin:admin:30:10:2:2

* Verify your NVP configuration::
   # run quantum-check-nvp-config to verify your nvp.ini configuration
   quantum-check-nvp-config /etc/quantum/plugins/nicira/nvp.ini

* Edit the /etc/quantum/dhcp_agent.ini::

   interface_driver = quantum.agent.linux.interface.OVSInterfaceDriver
   ovs_use_veth = True
   dhcp_driver = quantum.agent.linux.dhcp.Dnsmasq
   use_namespaces = True
   enable_isolated_metadata = True
   enable_metadata_network = True

* Update /etc/quantum/metadata_agent.ini::
   
   # The Quantum user information for accessing the Quantum API.
   auth_url = http://10.127.1.200:35357/v2.0
   auth_region = RegionOne
   admin_tenant_name = service
   admin_user = quantum
   admin_password = service_pass

   # IP address used by Nova metadata server
   nova_metadata_ip = 10.127.1.200

   # TCP Port used by Nova metadata server
   nova_metadata_port = 8775

   metadata_proxy_shared_secret = helloOpenStack

* Update /etc/sudoers
  # add the following entry for Quantum
  quantum ALL=(ALL) NOPASSWD:ALL

* Restart all quantum services::

   cd /etc/init.d/; for i in $( ls quantum-* ); do sudo service $i restart; done
   service dnsmasq restart

* Note: 'dnsmasq' fails to restart if already a service is running on port 53. In that case, kill that service before 'dnsmasq' restart

6. Nova
===========

6.1 KVM
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

6.2 Nova-*
------------------

* Start by installing nova components::

   apt-get install -y nova-api nova-cert novnc nova-consoleauth nova-scheduler nova-novncproxy nova-doc nova-conductor nova-compute-kvm

* Check the status of all nova-services::

   cd /etc/init.d/; for i in $( ls nova-* ); do service $i status; cd; done

* Prepare a Mysql database for Nova::

   mysql -u root -p
   CREATE DATABASE nova;
   GRANT ALL ON nova.* TO 'novaUser'@'%' IDENTIFIED BY 'novaPass';
   quit;

* Now modify authtoken section in the /etc/nova/api-paste.ini file to this::

   [filter:authtoken]
   paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
   auth_host = 10.10.1.200
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = nova
   admin_password = service_pass
   signing_dirname = /tmp/keystone-signing-nova
   # Workaround for https://bugs.launchpad.net/nova/+bug/1154809
   auth_version = v2.0

* Modify the /etc/nova/nova.conf like this::

   [DEFAULT]
   logdir=/var/log/nova
   state_path=/var/lib/nova
   lock_path=/run/lock/nova
   verbose=True
   api_paste_config=/etc/nova/api-paste.ini
   compute_scheduler_driver=nova.scheduler.simple.SimpleScheduler
   rabbit_host=10.10.1.200
   nova_url=http://10.10.1.200:8774/v1.1/
   sql_connection=mysql://novaUser:novaPass@10.10.1.200/nova
   root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf

   # Auth
   use_deprecated_auth=false
   auth_strategy=keystone

   # Imaging service
   glance_api_servers=10.10.1.200:9292
   image_service=nova.image.glance.GlanceImageService

   # Vnc configuration
   novnc_enabled=true
   novncproxy_base_url=http://10.127.1.200:6080/vnc_auto.html
   novncproxy_port=6080
   vncserver_proxyclient_address=10.10.1.200
   vncserver_listen=0.0.0.0
   
   # Metadata
   service_quantum_metadata_proxy = True
   quantum_metadata_proxy_shared_secret = helloOpenStack
   
   # Network settings
   network_api_class=nova.network.quantumv2.api.API
   quantum_url=http://10.10.1.200:9696
   quantum_auth_strategy=keystone
   quantum_admin_tenant_name=service
   quantum_admin_username=quantum
   quantum_admin_password=service_pass
   quantum_admin_auth_url=http://10.10.1.200:35357/v2.0
   libvirt_vif_driver=nova.virt.libvirt.vif.QuantumLinuxBridgeVIFDriver
   linuxnet_interface_driver=nova.network.linux_net.LinuxBridgeInterfaceDriver
   firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver

   # Compute #
   compute_driver=libvirt.LibvirtDriver
  
   # Cinder #
   volume_api_class=nova.volume.cinder.API
   osapi_volume_listen_port=5900

* Edit the /etc/nova/nova-compute.conf::

   [DEFAULT]
   libvirt_type=kvm
   compute_driver=libvirt.LibvirtDriver
   libvirt_vif_type=ethernet
   libvirt_vif_driver=nova.virt.libvirt.vif.QuantumLinuxBridgeVIFDriver
    
* Synchronize your database::

   nova-manage db sync

* Restart nova-* services::

   cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; done   

* Check for the smiling faces on nova-* services to confirm your installation::

   nova-manage service list

7. Cinder
===========

* Install the required packages::

   apt-get install -y cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms

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
   paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
   service_protocol = http
   service_host = 10.127.1.200
   service_port = 5000
   auth_host = 10.10.1.200
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = cinder
   admin_password = service_pass

* Edit the /etc/cinder/cinder.conf to::

   [DEFAULT]
   rootwrap_config=/etc/cinder/rootwrap.conf
   sql_connection = mysql://cinderUser:cinderPass@10.10.1.200/cinder
   api_paste_config = /etc/cinder/api-paste.ini
   iscsi_helper=ietadm
   volume_name_template = volume-%s
   volume_group = cinder-volumes
   verbose = True
   auth_strategy = keystone
   #osapi_volume_listen_port=5900

* Then, synchronize your database::

   cinder-manage db sync

* Finally, don't forget to create a volumegroup and name it cinder-volumes::

   cd /var/lib/cinder/volumes
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

* Update /etc/rc.local as follows to enable this volume upon reboot.

  # add the following line to /etc/rc.local before the 'exit 0' line
  losetup /dev/loop2 /var/lib/cinder/volumes/cinder-volumes

* Restart the cinder services::

   cd /etc/init.d/; for i in $( ls cinder-* ); do sudo service $i restart; done

* Verify if cinder services are running::

   cd /etc/init.d/; for i in $( ls cinder-* ); do sudo service $i status; done

8. Horizon
===========

* To install horizon, proceed like this ::

   apt-get install openstack-dashboard memcached

* If you don't like the OpenStack ubuntu theme, you can remove the package to disable it::

   dpkg --purge openstack-dashboard-ubuntu-theme

* Reload Apache and memcached::

   service apache2 restart; service memcached restart

You can now access your OpenStack **10.127.1.200/horizon** with credentials **admin:admin_pass**.

9. Creating VMs
================

To start your first VM, we first need to create a new tenant, user and internal network.

* Create a new tenant ::

   keystone tenant-create --name demo

* Create a new user and assign the member role to it in the new tenant (keystone role-list to get the appropriate id)::

   keystone user-create --name=user_one --pass=user_one --tenant-id $put_id_of_project_one --email=user_one@domain.com
   keystone user-role-add --tenant-id $put_id_of_project_one  --user-id $put_id_of_user_one --role-id $put_id_of_member_role

* Create a new network for the tenant::

   quantum net-create --tenant-id $put_id_of_project_one private1net 

* Create a new subnet inside the new tenant network::

   quantum subnet-create --tenant-id $put_id_of_project_one net_proj_one 10.0.1.0/24

* Create a router for the new tenant::

   quantum router-create --tenant-id $put_id_of_project_one private-router

* Add the router to the subnet::

   quantum router-interface-add $put_router_proj_one_id_here $put_subnet_id_here

* Create a VM instance::

   nova boot --image cirros-0.3.0 --flavor 1 --nic net-id=$put_id_of_net_proj_one testvm1

You should also be able to do all of these things using the OpenStack dashboard (Horizon) as well now.

10. Add another Compute Node
=============================

:Node Role: NICs
:Compute Node: eth0 (10.127.1.201), eth1 (10.10.1.201)

10.1. Preparing the Node
------------------

* After you install Ubuntu 12.04 Server 64bits, Go in sudo mode::

   sudo su

* Add Grizzly repositories [Only for Ubuntu 12.04]::

   apt-get install -y ubuntu-cloud-keyring 
   echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main >> /etc/apt/sources.list.d/grizzly.list


* Update your system::

   apt-get update -y
   apt-get upgrade -y
   apt-get dist-upgrade -y

* Install ntp service::

   apt-get install -y ntp

* Configure the NTP server to follow the controller node::
   
   #Comment the ubuntu NTP servers
   sed -i 's/server 0.ubuntu.pool.ntp.org/#server 0.ubuntu.pool.ntp.org/g' /etc/ntp.conf
   sed -i 's/server 1.ubuntu.pool.ntp.org/#server 1.ubuntu.pool.ntp.org/g' /etc/ntp.conf
   sed -i 's/server 2.ubuntu.pool.ntp.org/#server 2.ubuntu.pool.ntp.org/g' /etc/ntp.conf
   sed -i 's/server 3.ubuntu.pool.ntp.org/#server 3.ubuntu.pool.ntp.org/g' /etc/ntp.conf
   
   #Set the compute node to follow up your conroller node
   sed -i 's/server ntp.ubuntu.com/server 10.127.1.200/g' /etc/ntp.conf

   service ntp restart  

* Install other services::

   apt-get install -y vlan bridge-utils

* Enable IP_Forwarding::

   sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
   
   # To save you from rebooting, perform the following
   sysctl net.ipv4.ip_forward=1

10.2.Networking
------------

* Perform the following::
   
   # Management network
   auto eth0
   iface eth0 inet static
   address 10.127.1.201
   netmask 255.255.255.0

   # Data network
   auto eth1
   iface eth1 inet static
   address 10.10.1.201
   netmask 255.255.255.0

10.3 KVM
------------------

* make sure that your hardware enables virtualization::

   apt-get install -y cpu-checker
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

10.4. Open vSwitch
------------------

* Install Open vSwitch (Use the Nicira version from the nicira.com support web site)::

   download nvp-ovs-<version_string>-ubuntu_precise_amd64.gz
   tar -xzvf nvp-ovs*.gz
   apt-get install -y dkms libssl0.9.8
   dpkg -i openvswitch-*.deb
   dpkg -i nicira-ovs-hypervisor-node*.deb
   ovs-integrate nics-to-bridge eth0 eth1
  
   # Add the following to /etc/rc.local before 'exit 0'
   ifconfig eth0 0.0.0.0 up
   ifconfig breth0 10.127.1.201 netmask 255.255.255.0 up

   ifconfig eth1 0.0.0.0 up
   ifconfig breth1 10.10.1.201 netmask 255.255.255.0 up

   route add default gw 10.127.1.1

* Verify Open vSwitch configuration to this point::

   ovs-vsctl show

   # you should have something like this

   Bridge "breth1"
      fail_mode: standalone
      Port "eth1"
          Interface "eth1"
      Port "breth1"
          Interface "breth1"
              type: internal
   Bridge "breth0"
      fail_mode: standalone
      Port "breth0"
          Interface "breth0"
              type: internal
      Port "eth0"
          Interface "eth0"
   Bridge br-int
      fail_mode: secure
      Port br-int
          Interface br-int
              type: internal

* Register this Hypervisor Transport Node (Open vSwitch) with Nicira NVP::

   # Set the open vswitch manager address
   ovs-vsctl set-manager ssl:<IP Address of one of your Nicira NVP controllers>

   # Get the client pki cert
   cat /etc/openvswitch/ovsclient-cert.pem

   # Copy the contents of the output including the BEGIN and END CERTIFICATE lines and be prepared to paste this into NVP manager
   # In NVP Manager add a new Hypervisor, follow the prompts and paste the client certificate when prompted
   # Please review the NVP User Guide for details on adding Hypervisor transport nodes to NVP for more information on this step

* Reboot the server and make sure you still have network connectivity::

   # an ifconfig should reveal eth0, eth1 interfaces that do not have IP addresses as well as breth0 and breth1 interfaces that do have IP addresses
   # you should be able to ping your upstream gateway 10.127.1.1, etc.


10.5. Nova
------------------

* Install nova's required components for the compute node::

   apt-get install -y nova-compute-kvm

* Now modify authtoken section in the /etc/nova/api-paste.ini file to this::

   [filter:authtoken]
   paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
   auth_host = 10.127.1.200
   auth_port = 35357
   auth_protocol = http
   admin_tenant_name = service
   admin_user = nova
   admin_password = service_pass
   signing_dirname = /tmp/keystone-signing-nova
   # Workaround for https://bugs.launchpad.net/nova/+bug/1154809
   auth_version = v2.0

* Edit /etc/nova/nova-compute.conf file ::

   [DEFAULT]
   libvirt_type=kvm
   compute_driver=libvirt.LibvirtDriver
   libvirt_ovs_bridge=br-int
   libvirt_vif_type=Ethernet
   libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtOpenVswitchDriver
   libvirt_use_virtio_for_bridges=True
   allow_admin_api=True


* Modify the /etc/nova/nova.conf like this::

   [DEFAULT]
   logdir=/var/log/nova
   state_path=/var/lib/nova
   lock_path=/run/lock/nova
   verbose=True
   api_paste_config=/etc/nova/api-paste.ini
   compute_scheduler_driver=nova.scheduler.simple.SimpleScheduler
   rabbit_host=10.127.1.200
   nova_url=http://10.127.1.200:8774/v1.1/
   sql_connection=mysql://novaUser:novaPass@10.127.1.200/nova
   root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf

   # Auth
   use_deprecated_auth=false
   auth_strategy=keystone

   # Imaging service
   glance_api_servers=10.127.1.200:9292
   image_service=nova.image.glance.GlanceImageService

   # Vnc configuration
   novnc_enabled=true
   novncproxy_base_url=http://10.127.1.200:6080/vnc_auto.html
   novncproxy_port=6080
   vncserver_proxyclient_address=10.127.1.201
   vncserver_listen=0.0.0.0

   # Network settings
   network_api_class=nova.network.quantumv2.api.API
   quantum_url=http://10.127.1.200:9696
   quantum_auth_strategy=keystone
   quantum_admin_tenant_name=service
   quantum_admin_username=quantum
   quantum_admin_password=service_pass
   quantum_admin_auth_url=http://10.127.1.200:35357/v2.0
   libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtOpenVswitchDriver
   linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver
   firewall_driver=nova.virt.firewall.NoopFirewallDriver
   security_group_api=quantum

   # Metadata
   service_quantum_metadata_proxy = True
   quantum_metadata_proxy_shared_secret = helloOpenStack

   # Compute
   compute_driver=libvirt.LibvirtDriver

   # Cinder
   volume_api_class=nova.volume.cinder.API
   osapi_volume_listen_port=5900
   cinder_catalog_info=volume:cinder:internalURL


* Restart nova-* services::

   service nova-compute restart

* Check for the smiling faces on nova-* services to confirm your installation::

   nova-manage service list
