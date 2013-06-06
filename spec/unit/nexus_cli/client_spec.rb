require 'spec_helper'

describe NexusCli::Client do
  let(:client) { described_class.new(configuration) }
  let(:configuration) do
    {
      "url" => "http://somewebsite.com",
      "repository" => "foo",
      "username" => "admin",
      "password" => "password"
    }
  end

  describe "#new" do
    it "makes a new one" do
      expect(client).to be_a(NexusCli::Client)
    end
  end
end
