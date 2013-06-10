module NexusCli
  class Resource

    include Celluloid

    def initialize(connection_registry)
      @connection_registry = connection_registry
    end

    # @return [NexusCli::Connection]
    def connection
      @connection_registry[:connection_pool]
    end

    # @param [Symbol] method
    def rest_request(method, path, *args)
      unless path.start_with?(Connection::NEXUS_REST_ENDPOINT)
        path.prepend(Connection::NEXUS_REST_ENDPOINT)
      end

      raw_request(method, path, *args).body
    end

    def base_request(method, path, *args)
      raw_request(method, path, *args).body
    end

    # @param [Symbol] method
    def raw_request(method, path, *args)
      unless Connection::METHODS.include?(method)
        #raise Errors::HTTPUnknownMethod, "unknown http method: #{method}"
      end

      connection.send(method, path, *args)
    rescue => ex
      abort(ex)
    end
  end
end
