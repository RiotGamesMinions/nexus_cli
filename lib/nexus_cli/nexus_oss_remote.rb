require 'restclient'
require 'nokogiri'
require 'tempfile'
require 'yaml'
require 'open3'

module NexusCli
  class OSSRemote < Remote

      def pull_artifact(artifact, destination, overrides)
        group_id, artifact_id, version, extension = parse_artifact_string(artifact)
        begin
          fileData = nexus['service/local/artifact/maven/redirect'].get({:params => {:r => configuration['repository'], :g => group_id, :a => artifact_id, :v => version, :e => extension}})
        rescue RestClient::ResourceNotFound
          raise ArtifactNotFoundException
        end
        artifact = nil
        destination = File.join(File.expand_path(destination || "."), "#{artifact_id}-#{version}.#{extension}")
        artifact = File.open(destination, 'w')
        artifact.write(fileData)
        artifact.close()
        File.expand_path(artifact.path)
      end

      def push_artifact(artifact, file, insecure, overrides)
        group_id, artifact_id, version, extension = parse_artifact_string(artifact)
        nexus['service/local/artifact/maven/content'].post({:hasPom => false, :g => group_id, :a => artifact_id, :v => version, :e => extension, :p => extension, :r => configuration['repository'],
          :file => File.new(file)}) do |response, request, result, &block|
          case response.code
          when 400
            raise BadUploadRequestException
          when 401
            raise PermissionsException
          when 403
            raise PermissionsException
          when 404
            raise CouldNotConnectToNexusException
          end
        end
      end

      def delete_artifact(artifact)
        group_id, artifact_id, version = parse_artifact_string(artifact)
        delete_string = "content/repositories/releases/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}"
        Kernel.quietly {`curl --request DELETE #{File.join(configuration['url'], delete_string)} -u #{configuration['username']}:#{configuration['password']}`}
      end

      def get_artifact_info(artifact, overrides)
        group_id, artifact_id, version, extension = parse_artifact_string(artifact)
        begin
          nexus['service/local/artifact/maven/resolve'].get({:params => {:r => configuration['repository'], :g => group_id, :a => artifact_id, :v => version, :e => extension}})
        rescue Errno::ECONNREFUSED => e
          raise CouldNotConnectToNexusException
        rescue RestClient::ResourceNotFound => e
          raise ArtifactNotFoundException
        end
      end
  end
end