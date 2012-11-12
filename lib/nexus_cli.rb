require 'nexus_cli/errors'

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
  autoload :LoggingMixin, 'nexus_cli/mixins/logging_mixin'

  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end

    def ui
      @ui ||= Thor::Shell::Color.new
    end
  end

  # Returns an HTTPClient instance with settings to connect
  # to a Nexus server.
  #
  # @return [HTTPClient]
  def nexus
    client = HTTPClient.new
    client.send_timeout = 6000
    client.receive_timeout = 6000
    # https://github.com/nahi/httpclient/issues/63
    client.set_auth(nil, configuration['username'], configuration['password'])
    client.www_auth.basic_auth.challenge(configuration['url'])
    client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @ssl_verify
    
    client
  end

  # Joins a given url to the current url stored in the configuraiton
  # and returns the combined String.
  #
  # @param [String] url
  #
  # @return [String]
  def nexus_url(url)
    File.join(configuration['url'], url)
  end

  # Gets that current status of the Nexus server. On a non-error
  # status code, returns a Hash of values from the server.
  #
  # @return [Hash]
  def status
    response = nexus.get(nexus_url("service/local/status"))
    case response.status
    when 200
      doc = Nokogiri::XML(response.content).xpath("/status/data")
      data = Hash.new
      data['app_name'] = doc.xpath("appName")[0].text
      data['version'] = doc.xpath("version")[0].text
      data['edition_long'] = doc.xpath("editionLong")[0].text
      data['state'] = doc.xpath("state")[0].text
      data['started_at'] = doc.xpath("startedAt")[0].text
      data['base_url'] = doc.xpath("baseUrl")[0].text
      return data
    when 401
      raise PermissionsException
    when 503
      raise CouldNotConnectToNexusException
    else
      raise UnexpectedStatusCodeException.new(response.status)
    end
  end

  # Determines whether or not the Nexus server being
  # connected to is running Nexus Pro.
  def running_nexus_pro?
    status['edition_long'] == "Professional"
  end
end