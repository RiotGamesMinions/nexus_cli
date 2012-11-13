module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  class OSSRemote
    attr_reader :configuration
    attr_reader :connection

    extend Forwardable
    def_delegators :@connection, :status, :parse_artifact_string, :nexus_url, :nexus

    include ArtifactsMixin
    include GlobalSettingsMixin
    include LoggingMixin
    include RepositoriesMixin
    include UsersMixin

    # @param [Hash] overrides
    # @param [Boolean] ssl_verify
    def initialize(overrides, ssl_verify=true)
      @configuration = Configuration::parse(overrides)
      @connection = Connection.new(configuration, ssl_verify)
    end
  end
end