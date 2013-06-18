module NexusCli
  class RuleObject
    class << self
      def from_nexus_response(response)
        attributes = Hash.new

        attributes[:group_id] = response.artifactCoordinate.groupId
        attributes[:artifact_id] = response.artifactCoordinate.artifactId
        attributes[:version] = response.artifactCoordinate.version
        attributes[:rule_type] = response.ruleTypeId.to_sym
        attributes[:value] = response.properties.first.value
        new(attributes)
      end
    end

    include Chozo::VariaModel

    attribute :group_id,
      type: String,
      required: true

    attribute :artifact_id,
      type: String,
      required: true

    attribute :version,
      type: String,
      required: true

    attribute :rule_type,
      type: Symbol,
      required: true

    attribute :value,
      type: [ TrueClass, FalseClass ],
      required: true

    def initialize(attributes)
      mass_assign(attributes)
    end

    def to_json(options)
      json = Hash.new
      json["artifactCoordinate"] = { groupId: self.group_id, artifactId: self.artifact_id, version: self.version }
      json["properties"] = get_properties
      json["ruleTypeId"] = self.rule_type
      
      enveloped = Hash.new
      enveloped["data"] = json
      JSON.dump(enveloped) 
    end

    def get_properties
      case self.rule_type
      when :simple
        [{key: "isApproved", value: self.value.to_s}]
      when :signature
        [{key: "requireSignature", value: self.value.to_s}]
      else
        # UNKNOWN RULE_TYPE
      end
    end
  end
end
