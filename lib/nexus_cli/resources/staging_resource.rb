module NexusCli
  class StagingResource
    def staging_upload(artifact_id, file)
      repository_path = repository_path_for(artifact_id)
      file_name = file_name_for(artifact_id)

      #"staging/deploy/maven2/#{repository_path}/#{file_name}"
      success = request(:put, "/staging/profiles/98dc4c4fd8729/#{repository_path}/#{file_name}", File.read(File.expand_path(file)))
      return success
    end
  end
end