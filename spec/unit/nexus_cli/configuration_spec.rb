require 'spec_helper'

describe NexusCli::Configuration do
  subject { configuration }
  let(:configuration) { described_class }
  let(:config_instance) { configuration.from_overrides(valid_config) }
  let(:valid_config) {
      {
        "url" => "http://somewebsite.com",
        "repository" => "foo",
        "username" => "admin",
        "password" => "password"
      }
    }

  describe "::from_overrides" do
    subject { from_overrides }
    let(:from_overrides) { configuration.from_overrides(valid_config) }

    it "returns a new Configuration object" do
      expect(from_overrides).to be_a(NexusCli::Configuration)
    end
  end

  describe "::from_file" do
    subject { from_file }
    let(:from_file) { configuration.from_file }

    before do
      YAML.stub(:load_file).and_return(valid_config)
    end

    context "when the NEXUS_CONFIG environment variable exists" do
      let(:nexus_config_path) { "/home/var/nexus_cli" }

      before do
        ENV['NEXUS_CONFIG'] = nexus_config_path
      end

      it "loads the config file from NEXUS_CONFIG" do
        YAML.should_receive(:load_file).with(nexus_config_path)
        from_file
      end
    end

    context "when the NEXUS_CONFIG environment variable does not exist" do
      let(:nexus_config_path) { File.expand_path(NexusCli::Configuration::DEFAULT_FILE) }

      before do
        ENV['NEXUS_CONFIG'] = nil
      end

      it "loads the config file from DEFAULT_FILE" do
        YAML.should_receive(:load_file).with(nexus_config_path)
        from_file
      end
    end

    it "returns a new Configuration object" do
      expect(from_file).to be_a(NexusCli::Configuration)
    end
  end

  describe "::validate_config" do
    subject { validate_config }
    let(:validate_config) { described_class.validate_config(config) }

    context "when a password is missing" do
      let(:config) {  valid_config.slice("url", "repository", "username") }

      it "raises an InvalidSettingsException" do
        expect { validate_config }.to raise_error(NexusCli::InvalidSettingsException)
      end
    end

    context "when a username is missing" do
      let(:config) {  valid_config.slice("url", "repository", "password") }

      it "raises an InvalidSettingsException" do
        expect { validate_config }.to raise_error(NexusCli::InvalidSettingsException)
      end

    end

    context "when a url is missing" do
      let(:config) {  valid_config.slice("password", "repository", "username") }

      it "raises an InvalidSettingsException" do
        expect { validate_config }.to raise_error(NexusCli::InvalidSettingsException)
      end
    end

    context "when a repository is missing" do
      let(:config) {  valid_config.slice("url", "password", "username") }

      it "raises an InvalidSettingsException" do
        expect { validate_config }.to raise_error(NexusCli::InvalidSettingsException)
      end
    end
  end

  describe "::sanitize_config" do
    subject { sanitize_config }
    let(:sanitize_config) { described_class.sanitize_config(valid_config) }

    context "when the repository has spaces" do
      let(:valid_config) {
        {
          "url" => "http://somewebsite.com",
          "repository" => "foo bar",
          "username" => "admin",
          "password" => "password"
        }
      }

      it "turns them into underscores" do
        expect(sanitize_config[:repository]).to eq("foo_bar")
        sanitize_config
      end
    end

    it "has indifferent access" do
      expect(sanitize_config["url"]).to eq(valid_config["url"])
      expect(sanitize_config[:url]).to eq(valid_config["url"])
    end
  end

  describe "#new" do
    subject { new_config }
    let(:new_config) { described_class.new(url, repository, username, password) }
    let(:url) { "http://some-url.com" }
    let(:repository) { "releases" }
    let(:username) { "kallan" }
    let(:password) { "password" }


    it "creates a new Configuration object" do
      expect(new_config).to be_a(NexusCli::Configuration)
    end
  end

  describe "#url" do  
    it "returns the url" do
      expect(config_instance.url).to eq("http://somewebsite.com")
    end
  end

  describe "#repository" do
    it "returns the repository" do
      expect(config_instance.repository).to eq("foo")
    end
  end

  describe "#username" do
    it "returns the username" do
      expect(config_instance.username).to eq("admin")
    end
  end

  describe "#password" do
    it "returns the password" do
      expect(config_instance.password).to eq("password")
    end
  end
end
