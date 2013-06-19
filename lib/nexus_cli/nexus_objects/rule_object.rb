module NexusCli
  class RuleObject < NexusObject

    attribute :id,
      type: String

    attribute 'artifact_coordinate.group_id',
      type: String,
      required: true
    def_delegator :artifact_coordinate, :group_id, :group_id

    attribute 'artifact_coordinate.artifact_id',
      type: String,
      required: true
    def_delegator :artifact_coordinate, :artifact_id, :artifact_id

    attribute 'artifact_coordinate.version',
      type: String,
      required: true
    def_delegator :artifact_coordinate, :version, :version

    attribute :rule_type_id,
      type: Symbol,
      required: true

    attribute :properties,
      type: Array

    def initialize(attributes)
      mass_assign(attributes)
    end
  end
end
