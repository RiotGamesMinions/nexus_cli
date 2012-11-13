module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  class OSSRemote
    attr_reader :configuration
    attr_reader :connection

    extend Forwardable
    def_delegator :@connection, :status, :status
    def_delegator :@connection, :parse_artifact_string, :parse_artifact_string
    def_delegator :@connection, :nexus_url, :nexus_url
    def_delegator :@connection, :nexus, :nexus

    include ArtifactsMixin
    include GlobalSettingsMixin
    include LoggingMixin
    include RepositoriesMixin
    include UsersMixin

    # @param [Hash] overrides
    # @param [Boolean] ssl_verify
    def initialize(overrides, ssl_verify=true)
      @configuration = Configuration::parse(overrides)
      @connection = Connection.new(configuration)
      @ssl_verify = ssl_verify
    end
  end
end