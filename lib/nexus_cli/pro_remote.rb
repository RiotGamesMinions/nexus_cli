module NexusCli
  class ProRemote
    attr_reader :configuration
    attr_reader :connection

    extend Forwardable
    def_delegator :@connection, :status, :status
    def_delegator :@connection, :parse_artifact_string, :parse_artifact_string
    def_delegator :@connection, :nexus_url, :nexus_url
    def_delegator :@connection, :nexus, :nexus
    
    include ArtifactsMixin
    include CustomMetadataMixin
    include GlobalSettingsMixin
    include LoggingMixin
    include RepositoriesMixin
    include SmartProxyMixin
    include UsersMixin

    # @param [Hash] overrides
    # @param [Boolean] ssl_verify
    def initialize(overrides, ssl_verify=true)
      @configuration = Configuration::parse(overrides)
      @connection = Connection.new(configuration, ssl_verify)
    end

    def get_license_info
      response = nexus.get(nexus_url("service/local/licensing"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def install_license(license_file)
      file = File.read(File.expand_path(license_file))
      response = nexus.post(nexus_url("service/local/licensing/upload"), :body => file, :header => {"Content-Type" => "application/octet-stream"})
      case response.status
      when 201
        return true
      when 403
        raise LicenseInstallFailure
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def install_license_bytes(bytes)
      response = nexus.post(nexus_url("service/local/licensing/upload"), :body => bytes, :header => {"Content-Type" => "application/octet-stream"})
      case response.status
      when 201
        return true
      when 403
        raise LicenseInstallFailure
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def transfer_artifact(artifact, from_repository, to_repository)
      do_transfer_artifact(artifact, from_repository, to_repository)
      
      configuration["repository"] = sanitize_for_id(from_repository)
      from_artifact_metadata = get_custom_metadata_hash(artifact)

      configuration["repository"] = sanitize_for_id(to_repository)
      to_artifact_metadata = get_custom_metadata_hash(artifact)

      do_update_custom_metadata(artifact, from_artifact_metadata, to_artifact_metadata)
    end

    private

    def create_add_trusted_key_json(params)
      JSON.dump(:data => params)
    end

    def create_smart_proxy_settings_json(params)
      JSON.dump(:data => params)
    end

    def create_pub_sub_json(params)
      JSON.dump(:data => params)
    end
  end
end