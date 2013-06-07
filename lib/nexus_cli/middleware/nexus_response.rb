module NexusCli
  module Middleware
    class NexusResponse < Faraday::Response::Middleware

      JSON_TYPE  = 'application/json'.freeze
      CONTENT_TYPE = 'content-type'.freeze

      BRACKETS   = [
        "[",
        "{"
      ].freeze

      WHITESPACE = [
        " ",
        "\n",
        "\r",
        "\t"
      ].freeze

      class << self
        # Parses a response from the Nexus server
        # into a JSON object, removing the extra "data"
        # envelope.
        #
        # @param  body [String]
        # 
        # @return [Hashie::Mash]
        def parse(body)
          result = JSON.parse(body)
          Hashie::Mash.new(format_for_nexus(result))
        end

        # Performs some extra formatting on the incoming json_object
        # by removing the Nexus "data" envelope if it exists and
        # snake-casing any camel cased keys in the JSON.
        #
        # @param  json_object [Hash]
        # 
        # @return [Hash]
        def format_for_nexus(json_object)
          result = remove_envelope(json_object)
          camel_case(result)
        end

        # Determines if the response of the given Faraday request env
        # contains JSON
        #
        # @param [Hash] env
        #   a Faraday request env
        #
        # @return [Boolean]
        def json_response?(env)
          response_type(env) == JSON_TYPE && looks_like_json?(env)
        end

        # Examines the body of a request env and returns true if it appears
        # to contain JSON or false if it does not
        #
        # @param [Hash] env
        #   a Faraday request env
        # @return [Boolean]
        def looks_like_json?(env)
          return false unless env[:body].present?

          BRACKETS.include?(first_char(env[:body]))
        end

        private

          def response_type(env)
            if env[:response_headers][CONTENT_TYPE].nil?
              return "text/html"
            end

            env[:response_headers][CONTENT_TYPE].split(';', 2).first
          end

          def first_char(body)
            idx = -1
            begin
              char = body[idx += 1]
              char = char.chr if char
            end while char && WHITESPACE.include?(char)

            char
          end


          def remove_envelope(json_object)
            json_object["data"] ? json_object["data"] : json_object
          end

          def camel_case(json_object)
            json_object.inject({}) do |hash, pair|
              hash[pair.first.underscore] = pair.last
              hash
            end
          end
      end

      def on_complete(env)
        if self.class.json_response?(env)
          parsed_result = self.class.parse(env[:body])
          env[:body] = parsed_result
        end
      end
    end
  end
end

Faraday.register_middleware(:response, nexus_response: NexusCli::Middleware::NexusResponse)
