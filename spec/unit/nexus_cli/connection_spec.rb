require 'spec_helper'

describe NexusCli::Connection do
  let(:connection) { described_class.new(configuration) }
  let(:configuration) { NexusCli::Configuration.new(config_options) }
  let(:config_options) do
    {
      "server_url" => "http://somewebsite.com",
      "repository" => "foo",
      "username" => "admin",
      "password" => "password"
    }
  end

  describe "#new" do
    
    it "sets an accept header of application/json" do
      expect(connection.headers).to include("Accept" => "application/json")
    end

    it "sets a content-type header of application/json" do
      expect(connection.headers).to include("Content-Type" => "application/json")
    end

    it "sets a user-agent header of NexusCli" do
      expect(connection.headers).to include("User-Agent")
    end

    it "sets ssl_verify" do
      expect(connection.ssl).to include(:verify)
    end
  end

  describe "#in_alternate_path" do
    it "should yield itself in an altnerate path" do
      expect{ |f| connection.in_alternate_path("/nexus", &f) }.to yield_with_args(connection)
    end

    it "should change the path_prefix" do
      connection.in_alternate_path("/nexus") do |yielded|
        expect(yielded.path_prefix).to eq("/nexus")
      end
    end

    context "when the block exits" do
      it "should change back to the old path_prefix" do
        connection.in_alternate_path("/nexus") { |yielded|}
        expect(connection.path_prefix).to eq("/#{NexusCli::Connection::NEXUS_REST_ENDPOINT}")
      end
    end
  end

  describe "#stream" do
    let(:stream) { described_class.new(configuration).stream(target, destination) }
    let(:target) { "http://test.it/file" }
    let(:destination) { tmp_path.join("test.file") }
    let(:contents) { "SOME STRING STUFF\nHERE.\n" }

    before(:each) do
      stub_request(:get, "http://test.it/file").to_return(status: 200, body: contents)
    end

    it "creates a destination file on disk" do
      stream

      File.exist?(destination).should be_true
    end

    it "contains the contents of the response body" do
      stream

      File.read(destination).should include(contents)
    end
  end

end
