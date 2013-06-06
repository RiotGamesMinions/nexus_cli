module NexusCli
  class Client
    attr_reader :configuration

    def initialize(overrides=nil)
      @configuration = overrides ? Configuration.from_overrides(overrides) : Configuration.from_file
    end

    def artifact
      
    end
  end
end
