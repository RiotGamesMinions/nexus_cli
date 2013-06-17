require 'spec_helper'

describe NexusCli::ProcurementResource do
  let(:procurement_resource) { described_class.new(connection_registry) }
  let(:connection_registry) { double(:[] => connection) }
  let(:connection) { double(:put => response, :post => response) }
  let(:response) { double(:body => {}, :headers => {}) }
  let(:repository) { "artifacts" }
  let(:procured_from_repository) { "procured" }

  describe "#start" do
    let(:start) { procurement_resource.start(repository, procured_from_repository) }

    it "starts procurement for the given repository" do
      connection.should_receive(:post).with(/procurement\/manage/, kind_of(String))
      start
    end
  end

  describe "#stop" do
  end

  describe "#add_rule" do
  end

  describe "#rules" do
  end
end
