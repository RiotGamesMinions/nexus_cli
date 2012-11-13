module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module SmartProxyMixin
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
      response = nexus.put(nexus_url("service/local/smartproxy/pub-sub/#{sanitize_for_id(repository_id)}"), :body => create_pub_sub_json(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def enable_artifact_subscribe(repository_id, preemptive_fetch)
      raise NotProxyRepositoryException.new(repository_id) unless Nokogiri::XML(get_repository_info(repository_id)).xpath("/repository/data/repoType").first.content == "proxy"

      params = {:repositoryId => repository_id}
      params[:subscribe] = true
      params[:preemptiveFetch] = preemptive_fetch
      artifact_subscribe(repository_id, params)
    end

    def disable_artifact_subscribe(repository_id)
      raise NotProxyRepositoryException.new(repository_id) unless Nokogiri::XML(get_repository_info(repository_id)).xpath("/repository/data/repoType").first.content == "proxy"

      params = {:repositoryId => repository_id}
      params[:subscribe] = false
      artifact_subscribe(repository_id, params)
    end

    def artifact_subscribe(repository_id, params)
      response = nexus.put(nexus_url("service/local/smartproxy/pub-sub/#{sanitize_for_id(repository_id)}"), :body => create_pub_sub_json(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
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
      response = nexus.put(nexus_url("service/local/smartproxy/settings"), :body => create_smart_proxy_settings_json(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
      when 200
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_smart_proxy_settings
      response = nexus.get(nexus_url("service/local/smartproxy/settings"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_smart_proxy_key
      response = nexus.get(nexus_url("service/local/smartproxy/settings"), :header => DEFAULT_ACCEPT_HEADER)
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
      response = nexus.post(nexus_url("service/local/smartproxy/trusted-keys"), :body => create_add_trusted_key_json(params), :header => DEFAULT_CONTENT_TYPE_HEADER)
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
      response = nexus.get(nexus_url("service/local/smartproxy/trusted-keys"), :header => DEFAULT_ACCEPT_HEADER)
      case response.status
      when 200
        return response.content
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end
  end
end