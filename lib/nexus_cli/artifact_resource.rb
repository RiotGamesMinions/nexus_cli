module NexusCli
  class ArtifactResource

    def initialize(connection)
      @connection = connection
    end

    def find(artifact_id)
      connection.get("artifact/maven/resolve", artifact_id.to_artifact_hash.merge({r: "releases"}))
    end

    def download(artifact_id, location = nil)
      destination = "mytest-1.0.0.tgz"
      File.open(destination, "wb") do |io|
        io.write(connection.get("artifact/maven/redirect", artifact_id.to_artifact_hash.merge({r: "releases"})).body)
      end
    end

    def connection
      @connection
    end
  end
end
