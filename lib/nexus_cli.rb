require 'nexus_cli/version'

module NexusCli
  autoload :Cli, 'nexus_cli/cli'
  autoload :Remote, 'nexus_cli/remote'
  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end
  end
end