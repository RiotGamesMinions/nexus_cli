module NexusCli
  class ArtifactResource

    def initialize(connection)
      @connection = connection
    end

    def find(artifact_id)
      artifact_id_hash = create_artifact_id_hash(artifact_id)
      puts artifact_id_hash
      connection.get("artifact/maven/resolve", artifact_id_hash)
    end

    def connection
      @connection
    end

    def create_artifact_id_hash(artifact_id)
      split = artifact_id.split(':')
      {
        g: split[0],
        a: split[1],
        v: split[2],
        e: split[3],
        r: "releases"
      }
    end
  end
end
