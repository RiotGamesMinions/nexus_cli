module NexusCli
  class StagingResource < NexusCli::Resource
    def upload(artifact_id, repository_id = nil, file)
      repository_path = repository_path_for(artifact_id)
      file_name = file_name_for(artifact_id)

      if repository_id.nil?
        success = rest_request(:put, "staging/deploy/maven2/#{repository_path}/#{file_name}", File.read(File.expand_path(file)))
      else
        rest_request(:put, "staging/deployByRepositoryId/#{repository_id}/#{repository_path}/#{file_name}", File.read(File.expand_path(file)))
      end
    end

    def close(repository_id)
      rest_request(:post, "staging/bulk/close", get_payload)
    end

    def drop(repository_id)
      rest_request(:post, "staging/bulk/drop", get_payload)
    end

    def get_payload
      json_payload = {"data" => {"stagedRepositoryIds" => ["rcs-008"],"description" => "Kyle!"}}

      JSON.dump(json_payload)
    end
  end
end
