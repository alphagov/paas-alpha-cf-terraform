Test for logstash
=================

Prerequisites
-------------

 * Install jruby: `rvm install jruby`
 * setup a gemset: `rvm use --create jruby@logstash`

Usage
-----

```
bundle install
bundle exec rspec parser/parse-cloudfoundry-logs_spec.rb
```

