module NexusCli
  class NexusObject < Buff::Config::JSON
    class << self
      def from_nexus_response(response)
        new(response.deep_transform_keys { |key| key.underscore } )
      end
    end

    extend Forwardable

    def to_json(options = {})
      attributes = Hash[{"data" => self._attributes_.to_hash}]
      JSON.dump(attributes.deep_transform_keys { |key| key.camelize(:lower) })
    end
  end
end
