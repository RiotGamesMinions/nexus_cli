require "nexus_cli/remote"
require "nexus_cli/cli"
require "nexus_cli/errors"

module NexusCli
  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end
  end
end