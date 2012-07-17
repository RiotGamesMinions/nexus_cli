require 'aruba/api'
World(Aruba::Api)

When /^I call the nexus "(.*?)" command$/ do |command|
  step "I run `nexus-cli #{command} --overrides=#{get_overrides}`"
end

When /^I push an artifact with the GAV of "(.*)"$/ do |gav|
  groupId, artifactId, version, extension = gav.split(":")
  file = File.new(File.join(temp_dir, "#{artifactId}-#{version}.#{extension}"), 'w')
  file.puts "some data"
  file.close
  step "I run `nexus-cli push #{gav} #{file.path}`"
end
