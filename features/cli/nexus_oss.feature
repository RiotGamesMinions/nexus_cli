Feature: Use the Nexus CLI
  As a CLI user
  I need commands to get Nexus status, push, pull
  
  Scenario: Get Nexus Status
    When I call the nexus "status" command
    Then the output should contain:
      """
      Application Name: Sonatype Nexus
      Version: 2.0.5
      """
    And the exit status should be 0

  Scenario: Push an Artifact
    When I push an artifact with the GAV of "com.test:mytest:1.0.0:tgz"
    Then the output should contain:
      """
      Artifact com.test:mytest:1.0.0:tgz has been successfully pushed to Nexus.
      """
    And the exit status should be 0
  
  @working
  Scenario: Pull an artifact
    When I call the nexus "pull com.test:mytest:1.0.0:tgz" command
    Then the output should contain:
    """
    Artifact has been retrived and can be found at path:
    """
    And the exit status should be 0

  @wip
  Scenario: Pull an artifact to a specific place
    When I want the artifact "com.riotgames.tar:mytar:1.0.3:tgz" in a temp directory
    Then I should have a copy of the "mytar-1.0.3.tgz" artifact in a temp directory

  @wip
  Scenario: Attempt to pull an artifact with the wrong parameters
    When I run `nexus-cli pull_artifact com.riotgames.whatever:something`
    Then I should expect an error because I need more colon separated values

  Scenario: Attempt to delete an artifact
    When I delete an artifact with the GAV of "com.test:mytest:1.0.0:tgz"
    And I call the nexus "info com.test:mytest:1.0.0:tgz" command
    Then the output should contain:
    """
    The artifact you requested information for could not be found. Please ensure it exists inside the Nexus.
    """
    And the exit status should be 101