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

    # Creates a repository that the Nexus uses to hold artifacts.
    # 
    # @param  name [String] the name of the repository to create
    # @param  proxy [Boolean] true if this is a proxy repository
    # @param  url [String] the url for the proxy repository to point to
    # @param  id [String] the id of repository 
    # @param  policy [String] repository policy (RELEASE|SNAPSHOT)
    # @param  provider [String] repo provider (maven2 by default)
    # 
    # @return [Boolean] returns true on success
    def create_repository(name, proxy, url, id, policy, provider)
      json = if proxy
        create_proxy_repository_json(name, url, id, policy, provider)
      else
        create_hosted_repository_json(name, id, policy, provider)
      end
      response = nexus.post(nexus_url("service/local/repositories"), :body => json, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 201
        return true
      when 400
        raise CreateRepsitoryException.new(response.content)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def delete_repository(name)
      response = nexus.delete(nexus_url("service/local/repositories/#{sanitize_for_id(name)}"))
      case response.status
      when 204
        return true
      when 404
        raise RepositoryDoesNotExistException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_repository_info(name)
      response = nexus.get(nexus_url("service/local/repositories/#{sanitize_for_id(name)}"))
      case response.status
      when 200
        return response.content
      when 404
        raise RepositoryNotFoundException
      when 503
        raise CouldNotConnectToNexusException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
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

    def create_group_repository(name, id, provider)
      response = nexus.post(nexus_url("service/local/repo_groups"), :body => create_group_repository_json(name, id, provider), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 201
        return true
      when 400
        raise CreateRepsitoryException.new(response.content)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_group_repository(group_id)
      response = nexus.get(nexus_url("service/local/repo_groups/#{sanitize_for_id(group_id)}"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      when 404
        raise RepositoryNotFoundException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def repository_in_group?(group_id, repository_to_check)
      group_repository = JSON.parse(get_group_repository(group_id))
      repositories_in_group = group_repository["data"]["repositories"]

      repositories_in_group.find{|repository| repository["id"] == sanitize_for_id(repository_to_check)}
    end

    def add_to_group_repository(group_id, repository_to_add_id)
      raise RepositoryInGroupException if repository_in_group?(group_id, repository_to_add_id)
      response = nexus.put(nexus_url("service/local/repo_groups/#{sanitize_for_id(group_id)}"), :body => create_add_to_group_repository_json(group_id, repository_to_add_id), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      when 400
        raise RepositoryNotFoundException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def remove_from_group_repository(group_id, repository_to_remove_id)
      raise RepositoryNotInGroupException unless repository_in_group?(group_id, repository_to_remove_id)
      response = nexus.put(nexus_url("service/local/repo_groups/#{sanitize_for_id(group_id)}"), :body => create_remove_from_group_repository_json(group_id, repository_to_remove_id), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def delete_group_repository(group_id)
      response = nexus.delete(nexus_url("service/local/repo_groups/#{sanitize_for_id(group_id)}"))
      case response.status
      when 204
        return true
      when 404
        raise RepositoryNotFoundException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def transfer_artifact(artifact, from_repository, to_repository)
      do_transfer_artifact(artifact, from_repository, to_repository)
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


    # Transfers an artifact from one repository
    # to another. Sometimes called a `promotion`
    # 
    # @param  artifact [String] a Maven identifier
    # @param  from_repository [String] the name of the from repository
    # @param  to_repository [String] the name of the to repository
    # 
    # @return [Boolean] returns true when successful
    def do_transfer_artifact(artifact, from_repository, to_repository)
      Dir.mktmpdir do |temp_dir|
        configuration["repository"] = sanitize_for_id(from_repository)
        artifact_file = pull_artifact(artifact, temp_dir)
        configuration["repository"] = sanitize_for_id(to_repository)
        push_artifact(artifact, artifact_file[:file_path])
      end
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

    def create_hosted_repository_json(name, id, policy, provider)
      params = {:provider => provider.nil? ? "maven2": provider}
      params[:providerRole] = "org.sonatype.nexus.proxy.repository.Repository"
      params[:exposed] = true
      params[:browseable] = true
      params[:indexable] = true
      params[:repoType] = "hosted"
      params[:repoPolicy] = policy.nil? ? "RELEASE" : ["RELEASE", "SNAPSHOT"].include?(policy) ? policy : "RELEASE" 
      params[:name] = name
      params[:id] = id.nil? ? sanitize_for_id(name) : sanitize_for_id(id)
      params[:format] = "maven2"
      JSON.dump(:data => params)
    end

    def create_proxy_repository_json(name, url, id, policy, provider)
      params = {:provider => provider.nil? ? "maven2" : provider}
      params[:providerRole] = "org.sonatype.nexus.proxy.repository.Repository"
      params[:exposed] = true
      params[:browseable] = true
      params[:indexable] = true
      params[:repoType] = "proxy"
      params[:repoPolicy] = policy.nil? ? "RELEASE" : ["RELEASE", "SNAPSHOT"].include?(policy) ? policy : "RELEASE" 
      params[:checksumPolicy] = "WARN"
      params[:writePolicy] = "READ_ONLY"
      params[:downloadRemoteIndexes] = true
      params[:autoBlockActive] = false
      params[:name] = name
      params[:id] = id.nil? ? sanitize_for_id(name) : sanitize_for_id(id)
      params[:remoteStorage] = {:remoteStorageUrl => url.nil? ? "http://change-me.com/" : url}
      JSON.dump(:data => params)
    end

    def create_user_json(params)
      JSON.dump(:data => params)
    end

    def create_change_password_json(params)
      JSON.dump(:data => params)
    end

    def create_logger_level_json(level)
      params = {:rootLoggerLevel => level.upcase}
      JSON.dump(:data => params)
    end

    def create_group_repository_json(name, id, provider)
      params = {:id => id.nil? ? sanitize_for_id(name) : sanitize_for_id(id)}
      params[:name] = name
      params[:provider] = provider.nil? ? "maven2" : provider
      params[:exposed] = true
      JSON.dump(:data => params)
    end

    def create_add_to_group_repository_json(group_id, repository_to_add_id)
      group_repository_json = JSON.parse(get_group_repository(group_id))
      repositories = group_repository_json["data"]["repositories"]
      repositories << {:id => sanitize_for_id(repository_to_add_id)}
      params = {:repositories => repositories}
      params[:id] = group_repository_json["data"]["id"]
      params[:name] = group_repository_json["data"]["name"]
      params[:exposed] = group_repository_json["data"]["exposed"]
      JSON.dump(:data => params)
    end

    def create_remove_from_group_repository_json(group_id, repository_to_remove_id)
      group_repository_json = JSON.parse(get_group_repository(group_id))
      repositories = group_repository_json["data"]["repositories"]

      repositories.delete(repository_in_group?(group_id, repository_to_remove_id))
      
      params = {:repositories => repositories}
      params[:id] = group_repository_json["data"]["id"]
      params[:name] = group_repository_json["data"]["name"]
      JSON.dump(:data => params)
    end

    def generate_fake_pom(pom_name, group_id, artifact_id, version, extension)
      Tempfile.open(pom_name) do |file|
        template_path = File.join(NexusCli.root, "data", "pom.xml.erb")
        file.puts ERB.new(File.read(template_path)).result(binding)
        file
      end
    end
  end
end