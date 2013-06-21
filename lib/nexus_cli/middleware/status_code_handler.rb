module NexusCli
  module Middleware
    class StatusCodeHandler < Faraday::Response::Middleware

      NEXUS_SUCCESS_STATUS_CODES = (200..210).to_a + [307]

      class << self
        def success?(env)
          NEXUS_SUCCESS_STATUS_CODES.include?(env[:status].to_i)
        end
      end

      def on_complete(env)
        unless self.class.success?(env)
          raise Errors::HTTPError.fabricate(env)
        end
      end
    end
  end
end

Faraday.register_middleware(:response, status_code_handler: NexusCli::Middleware::StatusCodeHandler)
