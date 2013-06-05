require 'spec_helper'

describe NexusCli::Connection do
  let(:server_url) { "https://repository.apache.org" }

  describe "#new" do
    let(:connection) { described_class.new(server_url) }
    
    it "sets an accept header of application/json" do
      expect(connection.headers).to include("Accept" => "application/json")
    end

    it "sets a content-type header of application/json" do
      expect(connection.headers).to include("Content-Type" => "application/json")
    end

    it "sets a user-agent header of NexusCli" do
      expect(connection.headers).to include("User-Agent")
    end
  end 
end
