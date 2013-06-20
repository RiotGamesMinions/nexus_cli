module NexusCli
  class StagingResource < NexusCli::Resource

    # Uploads an artifact to either the default deploy path or to a specific staging
    # repository, depending on the provided repository_id.
    #
    # @param  artifact_id [String] a colon-separated Nexus artifact identifier
    # @param  repository_id = nil [String] optional repository to upload to
    # @param  file [String] a path to the file to upload
    # 
    # @return [type] [description]
    def upload(artifact_id, repository_id = nil, file)
      repository_path = repository_path_for(artifact_id)
      file_name = file_name_for(artifact_id)

      if repository_id.nil?
        success = rest_request(:put, "staging/deploy/maven2/#{repository_path}/#{file_name}", File.read(File.expand_path(file)))
      else
        rest_request(:put, "staging/deployByRepositoryId/#{repository_id}/#{repository_path}/#{file_name}", File.read(File.expand_path(file)))
      end
    end

    # Closes the provided staging repository, making its artifacts available to
    # the group repositories in the staging profile.
    #
    # @param  repository_id [String] the repository id
    # @param  description = "Closing Repository" [String] an optional description
    # 
    # @return [type] [description]
    def close(repository_id, description = "Closing Repository")
      rest_request(:post, "staging/bulk/close", get_payload(repository_id, description))
    end

    # Drops the provided staging repository, deleting its artifacts from the Nexus
    # server.
    #
    # @param  repository_id [String] the repository id
    # @param  description = "Dropping Repository" [String] an optional description
    # 
    # @return [type] [description]
    def drop(repository_id, description = "Dropping Repository")
      rest_request(:post, "staging/bulk/drop", get_payload(repository_id, description))
    end

    # Promotes artifacts from one Staging Profile to another. In effect, this makes
    # the staged artifacts available to potentially different group repositories.
    #
    # @param  repository_id [String] the repository id
    # @param  promotion_id [String] the staging repository id to promote into
    # @param  description = "Promoting Repository" [String] an optional description
    # 
    # @return [type] [description]
    def promote(repository_id, promotion_id, description = "Promoting Repository")
      rest_request(:post, "staging/bulk/promote", get_payload(repository_id, promotion_id, description))
    end

    # Releases artifacts from their staging repository and into the configured Staging
    # Profile's target repository.
    #
    # @param  repository_id [String] the repository id
    # @param  description = "Releasing Repository" [String] an optional description
    # 
    # @return [type] [description]
    def release(repository_id, description = "Releasing Repository")
      rest_request(:post, "staging/bulk/promote", get_payload(repository_id, description))
    end

    # Returns an Array of the current Staging Profiles on the Nexus
    # server.
    #
    # @return [Array<StagingProfileObject] the current set
    # of staging repository profiles on the Nexus server
    def profiles
      response = rest_request(:get, "staging/profiles")
      response.data.collect { |profile| NexusCli::StagingProfileObject.from_nexus_response(profile) }
    end

    # Creates a new Staging Profile, which will intercept artifact uploads and place them
    # into staging repositories.
    #
    # @param  profile [NexusCli::StagingProfileObject] an object representation of
    #   the staging profile to create
    # 
    # @return [type] [description]
    def create_profile(profile)
      rest_request(:post, "staging/profiles", profile)
    end

    private
      def get_payload(repository_id, promotion_id = nil, description)
        json_payload = {"data" => {"stagedRepositoryIds" => Array(repository_id),"description" => description}}
        json_payload["stagingProfileGroup"] = promotion_id unless promotion_id.nil?
        JSON.dump(json_payload)
      end
  end
end
