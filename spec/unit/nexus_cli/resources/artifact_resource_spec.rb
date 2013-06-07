require 'spec_helper'

describe NexusCli::ArtifactResource do
  let(:artifact_resource) { described_class.new(connection) }
  let(:connection) { double('connection', :get => nil) }
  let(:artifact_id) { "com.test:my-test:1.0.0:tgz" }
  let(:artifact_id_hash) do
    {
      g: "com.test",
      a: "my-test",
      v: "1.0.0",
      e: "tgz",
      r: "releases"
    }
  end

  describe "#find" do
    let(:find) { artifact_resource.find(artifact_id) }

    it "attempts to find an artifact" do
      artifact_id_hash = { g: "com.test", a: "my-test", v: "1.0.0", e: "tgz", r: "releases"}
      connection.should_receive(:get).with("artifact/maven/resolve", artifact_id_hash)
      find
    end
  end

  describe "#download" do
    let(:download) { artifact_resource.download(artifact_id, location) }
    let(:location) { nil }

    it "attempts to download the artifact" do
      connection.should_receive(:get).with("artifact/maven/redirect", artifact_id_hash)
      download
    end

    context "when an alternate location is provided" do
      let(:location) { "/artifacts" }

      it "attempts to download the artifact to the provided location" do

        download
      end
    end
  end
end
