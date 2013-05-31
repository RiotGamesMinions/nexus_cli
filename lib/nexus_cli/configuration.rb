require 'extlib'
require 'chozo'

module NexusCli
  class Configuration
    DEFAULT_FILE = "~/.nexus_cli".freeze

    include Chozo::VariaModel

    attribute :url,
      type: String,
      required: true

    attribute :repository,
      type: String,
      required: true

    attribute :username,
      type: String,
      required: true

    attribute :password,
      type: String,
      required: true

    class << self
      # The filepath to the nexus cli configuration file
      #
      # @return [String]
      def file_path
        File.expand_path(ENV['NEXUS_CONFIG'] || File.expand_path(DEFAULT_FILE))
      end

      # @param [Hash] overrides
      #
      # @return [Hash]
      def from_overrides(overrides)
        raise MissingSettingsFileException unless overrides

        sanitized_config = sanitize_config(overrides)
        new(sanitized_config[:url], sanitized_config[:repository], sanitized_config[:username], sanitized_config[:password])
      end

      def from_file
        config = YAML.load_file(file_path)

        raise MissingSettingsFileException unless config

        sanitized_config = sanitize_config(config)
        new(sanitized_config[:url], sanitized_config[:repository], sanitized_config[:username], sanitized_config[:password])
      end

      def sanitize_config(config)
        config["repository"] = config["repository"].gsub(" ", "_").downcase
        config.with_indifferent_access
      end
    end

    def initialize(url, repository, username, password)
      set_attribute(:url, url)
      set_attribute(:repository, repository)
      set_attribute(:username, username)
      set_attribute(:password, password)
    end
  end
end
