require 'spec_helper'

describe NexusCli::Middleware::NexusResponse do

  describe "ClassMethods" do
    let(:env) { double() }

    describe ":parse" do
      let(:parse) { described_class.parse(json_string) }
      let(:json_string) { '{"data": {"foo": "bar"} }' }

      it "attempts to format the response for nexus" do
        described_class.should_receive(:format_for_nexus)
        parse
      end

      it "returns a Mash" do
        expect(parse).to be_a(Hashie::Mash)
      end
    end

    describe ":format_for_nexus" do
      let(:format_for_nexus) { described_class.format_for_nexus(json_object) }
      let(:json_object) do
        {
          "data" => {
            "foo" => "bar"
          }
        }
      end

      context "when the envelope exists" do
        it "removes the envelope" do
          expect(format_for_nexus).to include({"foo" => "bar"})
        end
      end

      context "when the envelope does not exist" do
        let(:json_object) { { "foo" => "bar" } }

        it "returns the json" do
          expect(format_for_nexus).to eq({"foo" => "bar"})
        end
      end

      context "when the keys are in snakeCase" do
        let(:json_object) { { "camelCase" => "yuck" } }

        it "converts the keys to camel_case" do
          expect(format_for_nexus).to eq({"camel_case" => "yuck"})
        end
      end
    end

    describe ":json_response?" do
      let(:json_response?) { described_class.json_response?(env) }

      context "when the response is believed to be JSON" do
        before do
          env.stub(:[]).with(:response_headers).and_return(
            'content-type' => 'application/json; charset=utf-8'
          )
          env.stub(:[]).with(:body).and_return("{\"name\":\"kyle\"}")
        end

        it "returns true" do
          expect(json_response?).to be_true
        end
      end

      context "when the response is not JSON" do
        before do
          env.stub(:[]).with(:response_headers).and_return(
            'content-type' => 'text/html; charset=utf-8'
          )
        end

        it "returns false" do
          expect(json_response?).to be_false
        end
      end
    end

    describe ":looks_like_json?" do
      let(:looks_like_json?) { described_class.looks_like_json?(env) }

      context "when the body looks like JSON" do
        before do
          env.stub(:[]).with(:body).and_return("{\"name\":\"kyle\"}")
        end

        it "returns true" do
          expect(looks_like_json?).to be_true
        end
      end

      context "when the body does not look like JSON" do
        before do
          env.stub(:[]).with(:body).and_return("name")
        end

        it "returns false" do
          expect(looks_like_json?).to be_false
        end
      end
    end
  end
end
