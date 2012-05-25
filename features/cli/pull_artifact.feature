@cli
Feature: Pull Artifact
  As a CLI user
  I need a command to pull artifacts from the Nexus repository
  So I have a way to get artifacts from a remote system to my local machine

  Scenario: Pull an artifact
    When I get the artifact:
    | artifactId | groupId | version | tgz |
    | "com.riotgames.artifact" | "my-artifact" | "1.0.0" | "tgz" |
    Then I should have a copy of the artifact on my computer