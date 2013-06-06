module NexusCli
  module Middleware
    class NexusResponse < Faraday::Response::Middleware

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

        private

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
        parsed_result = self.class.parse(env[:body])
        env[:body] = parsed_result
      end
    end
  end
end

Faraday.register_middleware(:response, nexus_response: NexusCli::Middleware::NexusResponse)
