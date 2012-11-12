module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module RepositoriesMixin
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
  end
end