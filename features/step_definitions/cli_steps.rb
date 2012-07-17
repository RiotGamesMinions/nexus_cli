require 'aruba/api'
World(Aruba::Api)

When /^I call the nexus "(.*?)" command$/ do |command|
  step "I run `nexus-cli #{command} --overrides=#{get_overrides}`"
end