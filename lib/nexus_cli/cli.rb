require 'thor'

module NexusCli
  class Cli < Thor
    desc "foo", "Prints foo"
    def foo
      puts "Hi Kyle"
    end
    desc "bar", "Prints something"
    def bar
      remote = Remote.new
      something = remote.getSomethingDifferent
      puts something
    end
    desc "pull_artifact artifact", "Pulls an artifact from Nexus and places it on your machine"
    def pull_artifact(artifact)
      remote = Remote.new
      remote.pull_artifact(artifact)
    end
  end
end