module NexusCli
  # @author Kyle Allan <kallan@riotgames.com>
  class Connection < Faraday::Connection

    NEXUS_REST_ENDPOINT = "service/local".freeze

    def initialize(server_url)
      options = {}
      options[:builder] = Faraday::Builder.new do |builder|
        builder.request :json
        builder.response :json
        builder.adapter :net_http_persistent
      end

      server_uri = Addressable::URI.parse(server_url).to_hash

      server_uri[:path] = File.join(server_uri[:path], NEXUS_REST_ENDPOINT)

      super(Addressable::URI.new(server_uri), options)
      @headers[:accept] = 'application/json'
      @headers[:content_type] = 'application/json'
      @headers[:user_agent] = "NexusCli v#{NexusCli::VERSION}"
    end
  end
end