#!/bin/sh

if [ $# -lt 2 ]; then
  echo "Usage: $0 <envname> <domain>"
  exit 1
fi

erb <<EOF
<%
  env="$1"
  domain="$2"
  adminuser="${3:-admin}"
  adminpass="${4:-fakepassword}"
%>{
  "suite_name"         : "CF_SMOKE_TESTS",
  "api"                : "api.<%= env %>.<%= domain %>",
  "apps_domain"        : "<%= env %>.<%= domain %>",
  "user"               : "<%= adminuser %>",
  "password"           : "<%= adminpass %>",
  "org"                : "CF-SMOKE-ORG",
  "space"              : "CF-SMOKE-SPACE",
  "cleanup"            : true,
  "use_existing_org"   : false,
  "use_existing_space" : false,
  "logging_app"        : "",
  "runtime_app"        : "",
  "skip_ssl_validation": true
}
EOF
