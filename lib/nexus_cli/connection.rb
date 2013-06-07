require 'open-uri'
require 'retryable'
require 'tempfile'
require 'zlib'

module NexusCli
  class Connection < Faraday::Connection

    NEXUS_REST_ENDPOINT = "service/local".freeze

    # Creates a new instance of the Connection class
    #
    # @param  server_url [String] the nexus server url
    # @param  configuration [NexusCli::Configuration] the nexus configuration
    def initialize(server_url, configuration = Configuration.from_file)
      options = {}
      options[:ssl] = {verify: configuration.ssl_verify}

      options[:builder] = Faraday::Builder.new do |builder|
        builder.request :json
        builder.request :url_encoded
        builder.request :basic_auth, configuration.username, configuration.password
        #builder.response :follow_redirects
        builder.response :nexus_response
        builder.adapter :net_http_persistent
      end

      server_uri = Addressable::URI.parse(server_url).to_hash

      server_uri[:path] = File.join(server_uri[:path], NEXUS_REST_ENDPOINT)

      super(Addressable::URI.new(server_uri), options)
      @headers[:accept] = 'application/json'
      @headers[:content_type] = 'application/json'
      @headers[:user_agent] = "NexusCli v#{NexusCli::VERSION}"
    end

    # Stream the response body of a remote URL to a file on the local file system
    #
    # @param [String] target
    #   a URL to stream the response body from
    # @param [String] destination
    #   a location on disk to stream the content of the response body to
    def stream(target, destination)
      FileUtils.mkdir_p(File.dirname(destination))

      target  = Addressable::URI.parse(target)
      headers = {}

      unless ssl[:verify]
        headers.merge!(ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
      end

      local = Tempfile.new('nexus-stream')
      local.binmode

      open(target, 'rb', headers) do |remote|
        until remote.eof?
          local.write(remote.read(1024))
        end
      end

      local.flush

      FileUtils.mv(local.path, destination)
    rescue OpenURI::HTTPError => ex
      abort(ex)
    ensure
      local.close(true) unless local.nil?
    end
  end
end
