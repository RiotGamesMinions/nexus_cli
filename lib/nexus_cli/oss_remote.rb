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

    include ArtifactMixin
    include GlobalSettingsMixin
    include UsersMixin
    include RepositoriesMixin

    # @param [Hash] overrides
    # @param [Boolean] ssl_verify
    def initialize(overrides, ssl_verify=true)
      @configuration = Configuration::parse(overrides)
      @ssl_verify = ssl_verify
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

    def get_logging_info
      response = nexus.get(nexus_url("service/local/log/config"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def set_logger_level(level)
      raise InvalidLoggingLevelException unless ["INFO", "DEBUG", "ERROR"].include?(level.upcase)
      response = nexus.put(nexus_url("service/local/log/config"), :body => create_logger_level_json(level), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
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

    # Formats the given XML into an [Array<String>] so it
    # can be displayed nicely.
    # 
    # @param  doc [Nokogiri::XML] the xml search results
    # @param  group_id [String] the group id
    # @param  artifact_id [String] the artifact id
    # 
    # @return [type] [description]
    def format_search_results(doc, group_id, artifact_id)
      versions = doc.xpath("//version").inject([]) {|array,node| array << "#{node.content()}"}
      if versions.length > 0
        indent_size = versions.max{|a,b| a.length <=> b.length}.size+4
        formated_results = ['Found Versions:']
        versions.inject(formated_results) do |array,version|
          temp_version = version + ":"
          array << "#{temp_version.ljust(indent_size)} `nexus-cli pull #{group_id}:#{artifact_id}:#{version}:tgz`"
        end
      else 
        formated_results = ['No Versions Found.']
      end 
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

    def create_logger_level_json(level)
      params = {:rootLoggerLevel => level.upcase}
      JSON.dump(:data => params)
    end
  end
end