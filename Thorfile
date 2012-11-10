# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)

require 'bundler'
require 'bundler/setup'

require 'thor/rake_compat'
require 'nexus_cli'

class Default < Thor  
  include Thor::RakeCompat
  Bundler::GemHelper.install_tasks

  desc "build", "Build nexus-cli-#{NexusCli.version}.gem into the pkg directory"
  def build
    Rake::Task["build"].execute
  end

  desc "install", "Build and install nexus-cli-#{NexusCli.version}.gem into system gems"
  def install
    Rake::Task["install"].execute
  end

  desc "release", "Create tag v#{NexusCli.version} and build and push nexus-cli-#{NexusCli.version}.gem to Rubygems"
  def release
    Rake::Task["release"].execute
  end

  class Spec < Thor
    include Thor::Actions

    namespace :spec
    default_task :all

    desc "all", "run all tests"
    def all
      invoke(:unit)
      invoke(:acceptance)
    end

    desc "unit", "run only unit tests"
    def unit
      run "rspec --color --format=documentation spec" 
    end

    desc "acceptance", "Run acceptance tests"
    def acceptance
      run "cucumber --color --format pretty"
    end
  end
end
