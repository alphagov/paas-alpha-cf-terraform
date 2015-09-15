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

properties:
  uaa:
    admin:
      client_secret: admin_secret
    batch:
      username: batch_username
      password: batch_password
    cc:
      client_secret: cc_client_secret
    clients:
      app-direct:
        secret: app-direct_secret
      developer_console:
        secret: developer_console_secret
      login:
        secret: login_client_secret
      notifications:
        secret: notification_secret
      doppler:
        secret: doppler_secret
      cloud_controller_username_lookup:
        secret: cloud_controller_username_lookup_secret
      gorouter:
        secret: gorouter_secret


    jwt:
      signing_key: |
        -----BEGIN RSA PRIVATE KEY-----
        MIICXAIBAAKBgQDHFr+KICms+tuT1OXJwhCUmR2dKVy7psa8xzElSyzqx7oJyfJ1
        JZyOzToj9T5SfTIq396agbHJWVfYphNahvZ/7uMXqHxf+ZH9BL1gk9Y6kCnbM5R6
        0gfwjyW1/dQPjOzn9N394zd2FJoFHwdq9Qs0wBugspULZVNRxq7veq/fzwIDAQAB
        AoGBAJ8dRTQFhIllbHx4GLbpTQsWXJ6w4hZvskJKCLM/o8R4n+0W45pQ1xEiYKdA
        Z/DRcnjltylRImBD8XuLL8iYOQSZXNMb1h3g5/UGbUXLmCgQLOUUlnYt34QOQm+0
        KvUqfMSFBbKMsYBAoQmNdTHBaz3dZa8ON9hh/f5TT8u0OWNRAkEA5opzsIXv+52J
        duc1VGyX3SwlxiE2dStW8wZqGiuLH142n6MKnkLU4ctNLiclw6BZePXFZYIK+AkE
        xQ+k16je5QJBAN0TIKMPWIbbHVr5rkdUqOyezlFFWYOwnMmw/BKa1d3zp54VP/P8
        +5aQ2d4sMoKEOfdWH7UqMe3FszfYFvSu5KMCQFMYeFaaEEP7Jn8rGzfQ5HQd44ek
        lQJqmq6CE2BXbY/i34FuvPcKU70HEEygY6Y9d8J3o6zQ0K9SYNu+pcXt4lkCQA3h
        jJQQe5uEGJTExqed7jllQ0khFJzLMx0K6tj0NeeIzAaGCQz13oo2sCdeGRHO4aDh
        HH6Qlq/6UOV5wP8+GAcCQFgRCcB+hrje8hfEEefHcFpyKH+5g1Eu1k0mLrxK2zd+
        4SlotYRHgPCEubokb2S1zfZDWIXW3HmggnGgM949TlY=
        -----END RSA PRIVATE KEY-----

      verification_key: |
        -----BEGIN PUBLIC KEY-----
        MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDHFr+KICms+tuT1OXJwhCUmR2d
        KVy7psa8xzElSyzqx7oJyfJ1JZyOzToj9T5SfTIq396agbHJWVfYphNahvZ/7uMX
        qHxf+ZH9BL1gk9Y6kCnbM5R60gfwjyW1/dQPjOzn9N394zd2FJoFHwdq9Qs0wBug
        spULZVNRxq7veq/fzwIDAQAB
        -----END PUBLIC KEY-----

    scim:
      users:
      - admin|fakepassword|scim.write,scim.read,openid,cloud_controller.admin,doppler.firehose
  loggregator_endpoint:
    shared_secret: secret
