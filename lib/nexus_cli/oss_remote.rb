require 'erb'
require 'httpclient'
require 'json'
require 'jsonpath'
require 'nokogiri'
require 'tempfile'
require 'yaml'

module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  class OSSRemote
    attr_reader :configuration

    include ArtifactsMixin
    include GlobalSettingsMixin
    include UsersMixin
    include RepositoriesMixin
    include LoggingMixin
    include NexusCli

    # @param [Hash] overrides
    # @param [Boolean] ssl_verify
    def initialize(overrides, ssl_verify=true)
      @configuration = Configuration::parse(overrides)
      @ssl_verify = ssl_verify
    end

    private

    # Transforms a given [String] into a sanitized version by
    # replacing spaces with underscores and downcasing.
    # 
    # @param  unsanitized_string [String] the String to sanitize
    # 
    # @return [String] the sanitized String
    def sanitize_for_id(unsanitized_string)
      unsanitized_string.gsub(" ", "_").downcase
    end

    # Parses a given artifact string into its
    # four, distinct, Maven pieces.
    # 
    # @param  artifact [String] the Maven identifier
    # 
    # @return [Array<String>] an Array with four elements
    def parse_artifact_string(artifact)
      split_artifact = artifact.split(":")
      if(split_artifact.size < 4)
        raise ArtifactMalformedException
      end
      group_id, artifact_id, version, extension = split_artifact
      version.upcase! if version.casecmp("latest")
      return group_id, artifact_id, version, extension
    end
  end
end