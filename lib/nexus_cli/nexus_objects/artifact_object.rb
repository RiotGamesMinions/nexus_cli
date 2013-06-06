module NexusCli
  class ArtifactObject
    include Chozo::VariaModel

    attribute :present_locally,
      type: [ TrueClass, FalseClass ]

    attribute :group_id,
      type: String,
      required: true

    attribute :artifact_id,
      type: String,
      required: true

    attribute :version,
      type: String,
      required: true

    attribute :extension,
      type: String,
      default: "jar"

    attribute :snapshot,
      type: [ TrueClass, FalseClass ]

    attribute :snapshotBuildNumber,
      type: Fixnum

    attribute :snapshot_time_stamp,
      type: Fixnum

    attribute :sha1,
      type: String

    attribute :repository_path,
      type: String

    def initialize(attributes)
      mass_assign(attributes)
    end
  end
end
