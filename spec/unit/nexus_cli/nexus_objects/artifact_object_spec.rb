require 'spec_helper'

describe NexusCli::ArtifactObject do
  let(:artifact_object) { described_class.new(attributes) }
  let(:attributes) do
    {
      group_id: "com.test",
      artifact_id: "mytest",
      version: "1.0.0",
      extension: "tgz"
    }
  end

  describe "#to_s" do
    let(:to_s) { artifact_object.to_s }

    it "returns a valid artifact identifier" do
      expect(to_s).to eq("com.test:mytest:1.0.0:tgz")
    end
  end
end
