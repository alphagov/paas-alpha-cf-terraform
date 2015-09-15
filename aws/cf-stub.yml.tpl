---
director_uuid: BOSH_UUID
name: CloudFoundry
meta:
  environment: ${environment}
  zones:
    z1: "${zone0}"
    z2: "${zone1}"


networks:
- name: cf1
  subnets:
    - range: 10.0.10.0/24
      gateway: 10.0.10.1
      dns: [10.0.0.2]
      reserved:
      - 10.0.10.2 - 10.0.10.9
      static:
      - 10.0.10.10 - 10.0.10.40
      cloud_properties:
        subnet: "${cf1_subnet_id}"
- name: cf2
  subnets:
    - range: 10.0.11.0/24
      gateway: 10.0.11.1
      reserved:
      - 10.0.11.2 - 10.0.11.9
      static:
      - 10.0.11.10 - 10.0.11.40
      cloud_properties:
        subnet: "${cf2_subnet_id}"
