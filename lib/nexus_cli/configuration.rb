require 'extlib'

module NexusCli
  class Configuration
    DEFAULT_FILE = "~/.nexus_cli".freeze

    attr_reader :url
    attr_reader :repository
    attr_reader :username
    attr_reader :password
    attr_reader :ssl_verify

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

        validate_config(overrides)
        sanitized_config = sanitize_config(overrides)
        new(sanitized_config[:url], sanitized_config[:repository], sanitized_config[:username], sanitized_config[:password])
      end

      def from_file
        config = YAML.load_file(file_path)

        raise MissingSettingsFileException unless config

        validate_config(config)
        sanitized_config = sanitize_config(config)
        new(sanitized_config[:url], sanitized_config[:repository], sanitized_config[:username], sanitized_config[:password])
      end

      def validate_config(configuration)
        ["url", "repository", "username", "password"].each do |key|
          raise InvalidSettingsException.new(key) if configuration[key].blank?
        end
      end

      def sanitize_config(config)
        config["repository"] = config["repository"].gsub(" ", "_").downcase
        config.with_indifferent_access
      end
    end

    def initialize(url, repository, username, password)
      @url = url
      @repository = repository
      @username = username
      @password = password
    end
  end
end
