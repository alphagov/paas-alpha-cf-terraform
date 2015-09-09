---
name: bosh

releases:
  - name: bosh
    url: https://bosh.io/d/github.com/cloudfoundry/bosh?v=190
    sha1: a0260b8cbcd3fba3a2885ddaa7040b8c4cb22a49
  - name: bosh-google-cpi
    url: http://storage.googleapis.com/bosh-stemcells/bosh-google-cpi-5.tgz
    sha1: c5de3053f233e6ef42c2a4228fa94179d955cc84

resource_pools:
  - name: vms
    network: public
    stemcell:
      url: http://storage.googleapis.com/bosh-stemcells/light-bosh-stemcell-2968-google-kvm-ubuntu-trusty-go_agent.tgz
      sha1: ce5a64c3ecef4fd3e6bd633260dfaa7de76540eb
    cloud_properties:
      machine_type: n1-standard-2
      root_disk_size_gb: 40
      root_disk_type: pd-standard

disk_pools:
  - name: disks
    disk_size: 32_768
    cloud_properties:
      type: pd-standard

networks:
  - name: private
    type: dynamic
    cloud_properties:
      network_name: ${gce_microbosh_net}
      ip_forwarding: true
      tags:
        - bosh
        - bastion
  - name: public
    type: vip

jobs:
  - name: bosh
    instances: 1

    templates:
      - {name: nats, release: bosh}
      - {name: redis, release: bosh}
      - {name: postgres, release: bosh}
      - {name: blobstore, release: bosh}
      - {name: director, release: bosh}
      - {name: health_monitor, release: bosh}
      - {name: registry, release: bosh-google-cpi}
      - {name: cpi, release: bosh-google-cpi}
      - {name: powerdns, release: bosh}

    resource_pool: vms
    persistent_disk_pool: disks

    networks:
      - name: private
        default: [dns, gateway]
      - name: public
        static_ips: ${gce_static_ip}

    properties:
      nats:
        address: 127.0.0.1
        user: nats
        password: nats-password

      redis:
        listen_address: 127.0.0.1
        address: 127.0.0.1
        password: redis-password

      postgres: &db
        host: 127.0.0.1
        user: postgres
        password: postgres-password
        database: bosh
        adapter: postgres

      registry:
        host: ${gce_static_ip}
        username: admin
        password: admin

      blobstore:
        address: ${gce_static_ip}
        provider: dav
        director: {user: director, password: director-password}
        agent: {user: agent, password: agent-password}

      director:
        address: 127.0.0.1
        name: my-bosh
        db: *db
        cpi_job: cpi
        max_threads: 10

      hm:
        director_account: {user: admin, password: admin}
        resurrector_enabled: true

      google: &google_properties
        project: ${gce_project_id}
        json_key: |
                    ACCOUNT_JSON
        default_zone: ${gce_default_zone}

      dns:
        address: ${gce_static_ip}
        domain_name: microbosh
        db: *db
        recursor: 8.8.8.8

      agent:
        mbus: nats://nats:nats@${gce_static_ip}:4222
        ntp: *ntp
        blobstore:
           options:
             endpoint: http://${gce_static_ip}:25250
             user: agent
             password: agent-password

      ntp: &ntp [169.254.169.254]

cloud_provider:
  template: {name: cpi, release: bosh-google-cpi}

  ssh_tunnel:
    host: ${gce_static_ip}
    port: 22
    user: ${gce_ssh_user}
    private_key: ${gce_ssh_key_path}

  mbus: https://mbus:mbus@${gce_static_ip}:6868

  properties:
    google: *google_properties
    agent:
      mbus: https://mbus:mbus@0.0.0.0:6868
      ntp: *ntp
      blobstore:
        provider: local
        options:
          blobstore_path: /var/vcap/micro_bosh/data/cache
