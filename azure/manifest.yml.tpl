#
# Template based on the file http://cloudfoundry.blob.core.windows.net/misc/bosh.yml
# as described in https://github.com/Azure/bosh-azure-cpi-release/blob/master/docs/guide.md#1-create-a-deployment-manifest
#
---
name: bosh

releases:
- name: bosh
  url: http://cloudfoundry.blob.core.windows.net/bosh/bosh-168+dev.preview2.tgz
  sha1: 363a42a0101b9cf822178a959ba36bd4de71c5f3
- name: bosh-azure-cpi
  url: http://cloudfoundry.blob.core.windows.net/azurecpi/bosh-azure-cpi-0+dev.preview2.tgz
  sha1: 5b46a278ce20e3712e7aad5396c5b0d2b93695cd

networks:
- name: private
  type: manual
  subnets:
  - range: 10.0.0.0/24
    gateway: 10.0.0.1
    dns: [8.8.8.8]
    cloud_properties:
      virtual_network_name: ${azure_vnet_name} # <--- Replace with virtual network name
      subnet_name: ${azure_subnet_name} # <--- Replace with subnet name for BOSH VM

resource_pools:
- name: vms
  network: private
  stemcell:
    url: http://cloudfoundry.blob.core.windows.net/stemcell/stemcell.preview2.tgz
    sha1: b05121f774aeaedbd66f6e735339be5c1bf85a5b
  cloud_properties:
    instance_type: Standard_D1

disk_pools:
- name: disks
  disk_size: 25_000

jobs:
- name: bosh
  templates:
  - {name: nats, release: bosh}
  - {name: redis, release: bosh}
  - {name: postgres, release: bosh}
  - {name: blobstore, release: bosh}
  - {name: director, release: bosh}
  - {name: health_monitor, release: bosh}
  - {name: registry, release: bosh}
  - {name: cpi, release: bosh-azure-cpi}

  instances: 1
  resource_pool: vms
  persistent_disk_pool: disks

  networks:
  - {name: private, static_ips: [10.0.0.4], default: [dns, gateway]}

  properties:
    nats:
      address: 127.0.0.1
      user: nats
      password: nats-password

    redis:
      listen_addresss: 127.0.0.1
      address: 127.0.0.1
      password: redis-password

    postgres: &db
      host: 127.0.0.1
      user: postgres
      password: postgres-password
      database: bosh
      adapter: postgres

    registry:
      address: 10.0.0.4
      host: 10.0.0.4
      db: *db
      http: {user: admin, password: admin, port: 25777}
      username: admin
      password: admin
      port: 25777

    blobstore:
      address: 10.0.0.4
      port: 25250
      provider: dav
      director: {user: director, password: director-password}
      agent: {user: agent, password: agent-password}

    director:
      address: 127.0.0.1
      name: bosh
      db: *db
      cpi_job: cpi
      enable_snapshots: true

    hm:
      http: {user: hm, password: hm-password}
      director_account: {user: admin, password: admin}

    azure: &azure
      environment: AzureCloud
      subscription_id: "${azure_subscription_id}" # <--- Replace with your subscription id
      storage_account_name: "${azure_storage_account_name}" # <--- Replace with your storage account name
      storage_access_key: "${azure_storage_access_key}" # <--- Replace with the access key of your storage account
      resource_group_name: "${azure_resource_group_name}" # <--- Replace with your resource group name
      tenant_id: "${azure_tenant_id}" # <--- Replace with your tenant id of the service principal
      client_id: "${azure_client_id}" # <--- Replace with your client id of the service principal
      client_secret: "${azure_client_secret}" # <--- Replace with your client secret of the service principal
      ssh_user: vcap
      ssh_certificate: "${azure_ssh_certificate}" # <--- Replace with the content of your ssh certificate

    agent: {mbus: "nats://nats:nats-password@10.0.0.4:4222"}

    ntp: &ntp [0.north-america.pool.ntp.org]

cloud_provider:
  template: {name: cpi, release: bosh-azure-cpi}

  ssh_tunnel:
    host: 10.0.0.4
    port: 22
    user: vcap # The user must be as same as above ssh_user
    private_key: ~/bosh # Path relative to this manifest file

  mbus: https://mbus-user:mbus-password@10.0.0.4:6868

  properties:
    azure: *azure
    agent: {mbus: "https://mbus-user:mbus-password@0.0.0.0:6868"}
    blobstore: {provider: local, path: /var/vcap/micro_bosh/data/cache}
    ntp: *ntp
