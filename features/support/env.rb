require 'aruba/cucumber'
$:.push "#{File.dirname(__FILE__)}/../../lib/"
require 'nexus_cli'
require 'rspec'

def get_overrides
  @overrides ||= {:url => 'http://localhost:8081/nexus', :repository => 'releases', :username => 'deployment', :password => 'deployment123'}
end