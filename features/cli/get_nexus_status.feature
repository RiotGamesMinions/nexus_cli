Feature: Get Nexus Status
  As a CLI user
  I need a command to get status information about the Nexus repository in a format I can consume
  So I can learn more about the Nexus I am using and use that information.

  @wip
  Scenario: Get Nexus Status
    When I call the nexus "status" command
    Then the output should contain:
      """
      Application Name: Sonatype Nexus
      Version: 2.0.5
      """
    And the exit status should be 0