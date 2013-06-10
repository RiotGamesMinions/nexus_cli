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
    def request(method, *args)
      raw_request(method, *args).body
    end

    # @param [Symbol] method
    def raw_request(method, *args)
      unless Connection::METHODS.include?(method)
        #raise Errors::HTTPUnknownMethod, "unknown http method: #{method}"
      end

      connection.send(method, *args)
    rescue => ex
      abort(ex)
    end
  end
end
