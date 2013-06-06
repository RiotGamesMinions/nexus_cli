module NexusCli
  class ArtifactResource

    def initialize(connection)
      @connection = connection
    end

    def find(artifact_id)
      connection.get("artifact/maven/resolve", artifact_id.to_artifact_hash.merge({r: "releases"}))
    end

    def connection
      @connection
    end
  end
end
