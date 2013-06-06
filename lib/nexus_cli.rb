require 'nexus_cli/core_ext'
require 'nexus_cli/errors'
require 'addressable/uri'
require 'faraday'
require 'faraday_middleware'
require 'rexml/document'
require 'yaml'
require 'active_support/core_ext/hash'

module NexusCli
  require_relative 'nexus_cli/client'
  require_relative 'nexus_cli/configuration'
  require_relative 'nexus_cli/connection'
  require_relative 'nexus_cli/artifact_resource'
  require_relative 'nexus_cli/nexus_objects/artifact_object'
  require_relative 'nexus_cli/middleware/nexus_response'

  def new(*args)
    Client.new(*args)
  end

  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end
  end
end
