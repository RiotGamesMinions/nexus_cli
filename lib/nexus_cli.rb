require 'nexus_cli/errors'
require 'nexus_cli/kernel'

module NexusCli
  DEFAULT_ACCEPT_HEADER = {
    "Accept" => "application/json"
  }.freeze
  
  DEFAULT_CONTENT_TYPE_HEADER = {
    "Content-Type" => "application/json"
  }.freeze

  autoload :Tasks, 'nexus_cli/tasks'
  autoload :Cli, 'nexus_cli/cli'
  autoload :RemoteFactory, 'nexus_cli/remote_factory'
  autoload :OSSRemote, 'nexus_cli/oss_remote'
  autoload :ProRemote, 'nexus_cli/pro_remote'
  autoload :Configuration, 'nexus_cli/configuration'
  autoload :N3Metadata, 'nexus_cli/n3_metadata'
  autoload :ArtifactsMixin, 'nexus_cli/mixins/artifacts_mixin'
  autoload :GlobalSettingsMixin, 'nexus_cli/mixins/global_settings_mixin'
  autoload :UsersMixin, 'nexus_cli/mixins/users_mixin'
  autoload :RepositoriesMixin, 'nexus_cli/mixins/repositories_mixin'

  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end

    def ui
      @ui ||= Thor::Shell::Color.new
    end
  end
end
