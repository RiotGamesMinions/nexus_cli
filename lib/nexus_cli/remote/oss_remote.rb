module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  class OSSRemote < BaseRemote

    include ArtifactsMixin
    include GlobalSettingsMixin
    include LoggingMixin
    include RepositoriesMixin
    include UsersMixin
  end
end