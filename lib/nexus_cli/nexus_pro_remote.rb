require 'restclient'
require 'nokogiri'
require 'tempfile'
require 'yaml'

module NexusCli
  class ProRemote < OSSRemote

    def get_artifact_custom_info(artifact)
      return N3Metadata::n3_to_xml(get_artifact_custom_info_n3(artifact))
    end

    def get_artifact_custom_info_n3(artifact)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      get_string = N3Metadata::generate_n3_path(group_id, artifact_id, version, extension, configuration['repository'])
      begin
        n3 = nexus[get_string].get
        if /<urn:maven#deleted>/.match(n3)
          raise ArtifactNotFoundException
        else
          return n3
        end
      rescue RestClient::ResourceNotFound => e
        raise ArtifactNotFoundException
      end
    end

    def update_artifact_custom_info(artifact, params)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      n3_user_urns = { "n3_header" => N3Metadata::get_n3_header(group_id, artifact_id, version, extension) }.merge(N3Metadata::generate_n3_contents_from_hash(parse_n3_params(params)))

      n3_temp = Tempfile.new("nexus_n3")
      begin
        n3_temp.write(N3Metadata::parse_n3_hash(n3_user_urns))
        n3_temp.close
        update_artifact_custom_info_n3(artifact, n3_temp.path)
      ensure
        n3_temp.close
        n3_temp.unlink
      end
    end

    def update_artifact_custom_info_n3(artifact, file)
      # Check if artifact exists before posting custom metadata.
      get_artifact_info(artifact)
      # Update the custom metadata using the n3 file.
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      post_string = N3Metadata::generate_n3_path(group_id, artifact_id, version, extension, configuration['repository'])

      # Get all the urn:nexus/user# keys and consolidate.
      # Read in nexus n3 file. If this is a newly-added artifact, there will be no n3 file so escape the exception.
      begin
        nexus_n3 = get_artifact_custom_info_n3(artifact)
      rescue ArtifactNotFoundException
        nexus_n3 = ""
      end

      # Read in local n3 file.
      local_n3 = File.open(file).read

      n3_user_urns = { "n3_header" => N3Metadata::get_n3_header(group_id, artifact_id, version, extension) }
      # Get the nexus keys.
      n3_user_urns = N3Metadata::generate_n3_contents_from_n3(nexus_n3, n3_user_urns)
      # Get the local keys and update the nexus keys.
      n3_user_urns = N3Metadata::generate_n3_contents_from_n3(local_n3, n3_user_urns)
      n3_temp = Tempfile.new("nexus_n3")
      begin
        n3_temp.write(N3Metadata::parse_n3_hash(n3_user_urns))
        n3_temp.close
        Kernel.quietly {`curl -T #{n3_temp.path} #{File.join(configuration['url'], post_string)} -u #{configuration['username']}:#{configuration['password']}`}
      ensure
        n3_temp.close
        n3_temp.unlink
      end
    end

    def clear_artifact_custom_info(artifact)
      get_artifact_info(artifact)
      group_id, artifact_id, version, extension = parse_artifact_string(artifact)
      post_string = N3Metadata::generate_n3_path(group_id, artifact_id, version, extension, configuration['repository'])
      n3_user_urns = { "n3_header" => N3Metadata::get_n3_header(group_id, artifact_id, version, extension) }
      n3_temp = Tempfile.new("nexus_n3")
      begin
        n3_temp.write(N3Metadata::parse_n3_hash(n3_user_urns))
        n3_temp.close
        Kernel.quietly {`curl -T #{n3_temp.path} #{File.join(configuration['url'], post_string)} -u #{configuration['username']}:#{configuration['password']}`}
      ensure
        n3_temp.close
        n3_temp.unlink
      end
    end

    def search_artifacts(params)
      docs = Array.new
      parse_search_params(params).each { |param|
        begin
          nexus['service/local/search/m2/freeform'].get ({params: {p: param[0], t: param[1], v: param[2]}}) do |response|
            raise BadSearchRequestException if response.code == 400
            docs.push(Nokogiri::XML(response.body).xpath("/search-results/data"))
          end
        rescue RestClient::ResourceNotFound => e
          raise ArtifactNotFoundException
        end
      }
      result = docs.inject(docs.first) {|memo,doc| get_common_artifact_set(memo, doc)}
      return result.nil? ? "" : result.to_xml(:indent => 4)
    end

    private
    def parse_n3_params(params)
      begin
        parsed_params = Hash.new
        params.split(",").each { |param|
          k,v = param.split(":")
          raise if /^[a-zA-Z0-9]+$/.match(k).nil?
          parsed_params[k] = v
        }
        return parsed_params
      rescue
        raise N3ParameterMalformedException
      end
    end

    def parse_search_params(params)
      parsed_params = params.split(",").collect {|param| param.split(":")}
      parsed_params.each { |param|
        raise SearchParameterMalformedException unless param.count == 3
      }
      return parsed_params
    end

    # Expects the XML set with `data` as root.
    def get_common_artifact_set(set1, set2)
      intersection = get_artifact_array(set1) & get_artifact_array(set2)
      return intersection.count > 0 ? Nokogiri::XML("<data>#{intersection.join}</data>").root : Nokogiri::XML("").root
    end

    def get_artifact_array(set)
      artifacts = Array.new
      artifact = nil
      set.to_s.split("\n").collect {|x| x.to_s.strip}.each { |piece|
        if piece == "<artifact>"
          artifact = piece
        elsif piece == "</artifact>"
          artifact += piece
          artifacts.push(artifact)
          artifact = nil
        elsif !artifact.nil?
          artifact += piece
        end
      }
      return artifacts
    end
  end
end
