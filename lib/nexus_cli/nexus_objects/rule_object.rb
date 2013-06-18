module NexusCli
  class RuleObject
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
