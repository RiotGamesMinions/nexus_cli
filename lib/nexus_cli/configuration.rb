require 'extlib'

module NexusCli
  module Configuration
    DEFAULT_FILE = "~/.nexus_cli".freeze

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
        sanitize_config(overrides)
      end

      def from_file
        config = YAML.load_file(file_path)

        raise MissingSettingsFileException unless config

        validate_config(config)
        sanitize_config(config)
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
  end
end
