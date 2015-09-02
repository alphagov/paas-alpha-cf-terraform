---
name: CloudFoundry manifest
director_uuid: TODO

releases:
- {name: cf, version: 210}

networks:
- name: private
  type: manual
  subnets:
  - range: 10.0.0.0/24
    gateway: 10.0.0.1
    dns: [10.0.0.2]
    reserved: ["10.0.0.2 - 10.0.0.9"]
    static: ["10.0.0.10 - 10.0.0.100"]
    cloud_properties: {subnet: ${aws_subnet_id}}

resource_pools:
- name: small_z1
  network: private
  stemcell:
    name: bosh-aws-xen-ubuntu-trusty-go_agent
    version: 3056
  cloud_properties:
    instance_type: t2.small

compilation:
  workers: 1
  network: private
  reuse_compilation_vms: true
  cloud_properties:
    instance_type: t2.medium

update:
  canaries: 1
  max_in_flight: 1
  serial: false
  canary_watch_time: 30000-600000
  update_watch_time: 5000-600000

jobs:
- name: nats_z1
  instances: 1
  resource_pool: small_z1
  templates:
  - {name: nats, release: cf}
  networks:
  - name: private
    static_ips: [10.0.0.10]
    cloud_properties:
      security_groups: [${default_security_group}, ${nats_security_group}]

properties:
  description: Cloud Foundry for Government PaaS
  networks: {apps: private}
  nats:
    machines: [10.0.0.10]
    password: PASSWORD
    port: 4222
    user: nats
  ssl:
    skip_cert_verify: true
  cloud_properties:
    availability_zone: ${aws_availability_zone}
    ephemeral_disk: {size: 25_000, type: gp2}
