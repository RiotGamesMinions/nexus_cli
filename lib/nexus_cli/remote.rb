require 'restclient'
require 'json'

module NexusCli
  class Remote
    class << self
      def nexus
        @nexus ||= RestClient::Resource.new 'http://guiness.riotgames.com:8081/nexus/'
      end
    end

    def getSomething
      response = RestClient.get 'http://build-lax-01:8080/api/json'
    end

    def getSomethingDifferent
      resource = RestClient::Resource.new 'http://build-lax-01:8080'
      response = resource['api/json'].get
      parsedData = JSON.parse(response)
      JSON.pretty_generate(parsedData)
    end

    def pull_artifact(artifact)
      splitArtifact = artifact.split(":")
      if(splitArtifact.size < 4)
        raise "Please give your artifact in the form of groupId:artifactId:version:type"
      end
      puts splitArtifact
      #puts self.class.nexus['service/local/all_repositories'].get
      #http://guiness.riotgames.com:8081/nexus/service/local/artifact/maven/redirect?r=riot&g=com.riotgames.tar&a=mytar&v=1.0.2&e=tgz
      file = self.class.nexus['service/local/artifact/maven/redirect'].get ({params: {r: 'riot', g: splitArtifact[0], a: splitArtifact[1], v: splitArtifact[2], e: splitArtifact[3]}})
      File.open("/Users/kallan/src/nexus-cli/#{splitArtifact[1]}-#{splitArtifact[2]}.#{splitArtifact[3]}", 'w') {|f| f.write(file)}
    end
  end
end