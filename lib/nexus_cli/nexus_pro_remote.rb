require 'httpclient'
require 'nokogiri'
require 'yaml'
require 'base64'

module NexusCli
  class ProRemote < OSSRemote
    def get_artifact_custom_info_raw(artifact)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      encoded_string = Base64.urlsafe_encode64(N3Metadata::create_custom_metadata_subject(group_id, artifact_id, version, extension))
      response = nexus.get(nexus_url("service/local/index/custom_metadata/#{configuration['repository']}/#{encoded_string}"))
      case response.status
      when 200
        if N3Metadata::missing_custom_metadata?(response.content)
          raise N3NotFoundException
        else
          return response.content
        end
      when 404
        raise ArtifactNotFoundException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_artifact_custom_info(artifact)
      N3Metadata::parse_request_into_simple(get_artifact_custom_info_raw(artifact))
    end

    def update_artifact_custom_info(artifact, *params)
      target_n3 = parse_custom_metadata_update_params(*params)

      # Get all the urn:nexus/user# keys and consolidate.
      # Read in nexus n3 file. If this is a newly-added artifact, there will be no n3 file so escape the exception.
      begin
        nexus_n3 = N3Metadata::parse_request_into_hash(get_artifact_custom_info_raw(artifact))
      rescue N3NotFoundException
        nexus_n3 = {}
      end

      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      encoded_string = Base64.urlsafe_encode64(N3Metadata::create_custom_metadata_subject(group_id, artifact_id, version, extension))
      response = nexus.post(nexus_url("service/local/index/custom_metadata/#{configuration['repository']}/#{encoded_string}"), :body => create_custom_metadata_update_json(nexus_n3, target_n3), :header => {"Content-Type" => "application/json"})
      case response.code
      when 201
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def clear_artifact_custom_info(artifact)
      get_artifact_custom_info(artifact) # Check that artifact has custom metadata
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      encoded_string = Base64.urlsafe_encode64(N3Metadata::create_custom_metadata_subject(group_id, artifact_id, version, extension))
      response = nexus.post(nexus_url("service/local/index/custom_metadata/#{configuration['repository']}/#{encoded_string}"), :body => create_custom_metadata_clear_json, :header => {"Content-Type" => "application/json"})
      case response.status
      when 201
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def search_artifacts(*params)
      docs = Array.new
      parse_custom_metadata_search_params(*params).each do |param|
        response = nexus.get(nexus_url("service/local/search/m2/freeform"), :query => {:p => param[0], :t => param[1], :v => param[2]})
        case response.status
        when 200
          docs.push(Nokogiri::XML(response.body).xpath("/search-results/data"))
        when 400
          raise BadSearchRequestException
        when 404
          raise ArtifactNotFoundException
        else
          raise UnexpectedStatusCodeException.new(response.status)
        end
      end
      result = docs.inject(docs.first) {|memo,doc| get_common_artifact_set(memo, doc)}
      return result.nil? ? "" : result.to_xml(:indent => 4)
    end

    def get_pub_sub(repository_id)
      response = nexus.get(nexus_url("service/local/smartproxy/pub-sub/#{repository_id}"))
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def enable_artifact_publish(repository_id)
      params = {:repositoryId => repository_id}
      params[:publish] = true
      artifact_publish(repository_id, params)
    end

    def disable_artifact_publish(repository_id)
      params = {:repositoryId => repository_id}
      params[:publish] = false
      artifact_publish(repository_id, params)
    end

    def artifact_publish(repository_id, params)
      response = nexus.put(nexus_url("service/local/smartproxy/pub-sub/#{repository_id}"), :body => create_pub_sub_json(params), :header => {"Content-Type" => "application/json"})
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def enable_artifact_subscribe(repository_id)
      raise NotProxyRepositoryException.new(repository_id) unless Nokogiri::XML(get_repository_info(repository_id)).xpath("/repository/data/repoType").first.content == "proxy"

      params = {:repositoryId => repository_id}
      params[:subscribe] = true
      artifact_subscribe(repository_id, params)
    end

    def disable_artifact_subscribe(repository_id)
      raise NotProxyRepositoryException.new(repository_id) unless Nokogiri::XML(get_repository_info(repository_id)).xpath("/repository/data/repoType").first.content == "proxy"

      params = {:repositoryId => repository_id}
      params[:subscribe] = false
      artifact_subscribe(repository_id, params)
    end

    def artifact_subscribe(repository_id, params)
      response = nexus.put(nexus_url("service/local/smartproxy/pub-sub/#{repository_id}"), :body => create_pub_sub_json(params), :header => {"Content-Type" => "application/json"})
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def enable_smart_proxy(host=nil, port=nil)
      params = {:enabled => true}
      params[:host] = host unless host.nil?
      params[:port] = port unless port.nil?
      smart_proxy(params)
    end

    def disable_smart_proxy
      params = {:enabled => false}
      smart_proxy(params)
    end

    def smart_proxy(params)
      response = nexus.put(nexus_url("service/local/smartproxy/settings"), :body => create_smart_proxy_settings_json(params), :header => {"Content-Type" => "application/json"})
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_smart_proxy_settings
      response = nexus.get(nexus_url("service/local/smartproxy/settings"), :header => {"Accept" => "application/json"})
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_smart_proxy_key
      response = nexus.get(nexus_url("service/local/smartproxy/settings"), :header => {"Accept" => "application/json"})
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def add_trusted_key(certificate, description, path=true)
      params = {:description => description}
      params[:certificate] = path ? File.read(File.expand_path(certificate)) : certificate
      response = nexus.post(nexus_url("service/local/smartproxy/trusted-keys"), :body => create_add_trusted_key_json(params), :header => {"Content-Type" => "application/json"})
      case response.status
      when 201
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def delete_trusted_key(key_id)
      response = nexus.delete(nexus_url("service/local/smartproxy/trusted-keys/#{key_id}"))
      case response.status
      when 204
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_trusted_keys
      response = nexus.get(nexus_url("service/local/smartproxy/trusted-keys"), :header => {"Accept" => "application/json"})
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_license_info
      response = nexus.get(nexus_url("service/local/licensing"), :header => {"Accept" => "application/json"})
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

    def parse_custom_metadata_update_params(*params)
      begin
        parsed_params = {}
        params.each do |param|
          # param = key:value
          c1 = param.index(":")
          key = param[0..(c1 - 1)]
          value = param[(c1 + 1)..-1]
          if !c1.nil? && N3Metadata::valid_n3_key?(key) && N3Metadata::valid_n3_value?(value)
            parsed_params[key] = value
          else
            raise
          end
        end
        return parsed_params
      rescue
        raise N3ParameterMalformedException
      end
    end

    def parse_custom_metadata_search_params(*params)
      begin
        parsed_params = []
        params.each do |param|
          # param = key:type:value
          c1 = param.index(":")
          c2 = param.index(":", (c1 + 1))
          key = param[0..(c1 - 1)]
          type = param[(c1 + 1)..(c2 - 1)]
          value = param[(c2 + 1)..-1]
          if !c1.nil? && !c2.nil? && N3Metadata::valid_n3_key?(key) && N3Metadata::valid_n3_value?(value) && N3Metadata::valid_n3_search_type?(type)
            parsed_params.push([key, type, value])
          else
            raise
          end
        end
        return parsed_params
      rescue
        raise SearchParameterMalformedException
      end
    end

    def create_custom_metadata_update_json(source, target)
      JSON.dump(:data => N3Metadata::generate_request_from_hash(source, target))
    end

    def create_custom_metadata_clear_json
      JSON.dump(:data => {})
    end

    # Expects the XML set with `data` as root.
    def get_common_artifact_set(set1, set2)
      intersection = get_artifact_array(set1) & get_artifact_array(set2)
      return intersection.count > 0 ? Nokogiri::XML("<data>#{intersection.join}</data>").root : Nokogiri::XML("").root
    end

    # Collect <artifact>...</artifact> elements into an array.
    # This will allow use of array intersection to find common artifacts in searches.
    def get_artifact_array(set)
      artifacts = []
      artifact = nil
      set.to_s.split("\n").collect {|x| x.to_s.strip}.each do |piece|
        if piece == "<artifact>"
          artifact = piece
        elsif piece == "</artifact>"
          artifact += piece
          artifacts.push(artifact)
          artifact = nil
        elsif !artifact.nil?
          artifact += piece
        end
      end
      return artifacts
    end
  end
end
