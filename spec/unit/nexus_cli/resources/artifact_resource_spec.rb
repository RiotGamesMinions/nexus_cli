require 'spec_helper'

describe NexusCli::ArtifactResource do
  let(:artifact_resource) { described_class.new(connection) }
  let(:connection) { NexusCli::Connection.new(configuration["url"], configuration) }
  let(:configuration) { NexusCli::Configuration.new(config_options) }
  let(:config_options) do
    {
      "url" => "http://somewebsite.com",
      "repository" => "foo",
      "username" => "admin",
      "password" => "password"
    }
  end

  before do
    connection.stub(:get).and_return(nil)
  end

  it "can find an artifact" do
    expect(artifact_resource.find).to be_nil
  end
end
