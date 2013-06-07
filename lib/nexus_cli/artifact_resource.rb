module NexusCli
  class ArtifactResource

    def initialize(connection)
      @connection = connection
    end

    def find(artifact_id)
      connection.get("artifact/maven/resolve", artifact_id.to_artifact_hash.merge({r: "releases"}))
    end

    def download(artifact_id, location = ".")
      destination = "mytest-1.0.0.tgz"

      redirect_url = connection.get("artifact/maven/redirect", artifact_id.to_artifact_hash.merge({r: "releases"})).headers["location"]
      p :redirect_url, redirect_url
      connection.stream(redirect_url, File.join(File.expand_path(location), destination))
    end

    def connection
      @connection
    end
  end
end
