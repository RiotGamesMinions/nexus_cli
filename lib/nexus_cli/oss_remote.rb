module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  class OSSRemote
    attr_reader :configuration

    include ArtifactsMixin
    include GlobalSettingsMixin
    include LoggingMixin
    include NexusCli
    include RepositoriesMixin
    include UsersMixin

    # @param [Hash] overrides
    # @param [Boolean] ssl_verify
    def initialize(overrides, ssl_verify=true)
      @configuration = Configuration::parse(overrides)
      @ssl_verify = ssl_verify
    end
  end
end