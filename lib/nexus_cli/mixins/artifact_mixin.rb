module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  module ArtifactMixin
    # Retrieves a file from the Nexus server using the given [String] artifact
    # identifier. Optionally provide a destination [String].
    #
    # @param [String] artifact
    # @param [String] destination
    #
    # @return [Hash] Some information about the artifact that was pulled.
    def pull_artifact(artifact, destination=nil)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      version = Nokogiri::XML(get_artifact_info(artifact)).xpath("//version").first.content() if version.casecmp("latest")
      file_name = "#{artifact_id}-#{version}.#{extension}"
      destination = File.join(File.expand_path(destination || "."), file_name)
      response = nexus.get(nexus_url("service/local/artifact/maven/redirect"), :query => {:g => group_id, :a => artifact_id, :v => version, :e => extension, :r => configuration['repository']})
      case response.status
      when 301, 307
        # Follow redirect and stream in chunks.
        artifact_file = File.open(destination, "wb") do |io|
          nexus.get(response.content.gsub(/If you are not automatically redirected use this url: /, "")) do |chunk|
            io.write(chunk)
          end
        end
      when 404
        raise ArtifactNotFoundException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
      {
        :file_name => file_name,
        :file_path => File.expand_path(destination),
        :version   => version,
        :size      => File.size(File.expand_path(destination))
      }
    end


    # Pushes the given [file] to the Nexus server
    # under the given [artifact] identifier.
    # 
    # @param  artifact [String] the Maven identifier
    # @param  file [type] the path to the file
    # 
    # @return [Boolean] returns true when successful
    def push_artifact(artifact, file)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      file_name = "#{artifact_id}-#{version}.#{extension}"
      put_string = "content/repositories/#{configuration['repository']}/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}/#{file_name}"
      response = nexus.put(nexus_url(put_string), File.open(file))

      case response.status
      when 201
        pom_name = "#{artifact_id}-#{version}.pom"
        put_string = "content/repositories/#{configuration['repository']}/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}/#{pom_name}"
        pom_file = generate_fake_pom(pom_name, group_id, artifact_id, version, extension)
        nexus.put(nexus_url(put_string), File.open(pom_file))
        delete_string = "/service/local/metadata/repositories/#{configuration['repository']}/content/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}"
        nexus.delete(nexus_url(delete_string))
        return true
      when 400
        raise BadUploadRequestException
      when 401
        raise PermissionsException
      when 403
        raise PermissionsException
      when 404
        raise NexusHTTP404.new(response.content)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def delete_artifact(artifact)
      group_id, artifact_id, version = parse_artifact_string(artifact)
      response = nexus.delete(nexus_url("content/repositories/#{configuration['repository']}/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}"))
      case response.status
      when 204
        return true
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def get_artifact_info(artifact)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      response = nexus.get(nexus_url("service/local/artifact/maven/resolve"), :query => {:g => group_id, :a => artifact_id, :v => version, :e => extension, :r => configuration['repository']})
      case response.status
      when 200
        return response.content
      when 404
        raise ArtifactNotFoundException
      when 503
        raise CouldNotConnectToNexusException
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end


    # Searches for an artifact using the given identifier.
    #
    # @param  artifact [String] the Maven identifier
    # @example com.artifact:my-artifact
    # 
    # @return [Array<String>] a formatted Array of results
    # @example 
    #   1.0.0     `nexus-cli pull com.artifact:my-artifact:1.0.0:tgz`
    #   2.0.0     `nexus-cli pull com.artifact:my-artifact:2.0.0:tgz`
    #   3.0.0     `nexus-cli pull com.artifact:my-artifact:3.0.0:tgz`
    def search_for_artifacts(artifact)
      group_id, artifact_id = artifact.split(":")
      response = nexus.get(nexus_url("service/local/data_index"), :query => {:g => group_id, :a => artifact_id})
      case response.status
      when 200
        doc = Nokogiri::XML(response.content)
        return format_search_results(doc, group_id, artifact_id)
      else
        raise UnexpectedStatusCodeException.new(response.status)
      end
    end
  end
end