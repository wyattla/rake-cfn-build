Feature: Run rake tasks

  Scenario: Validate AWS variables in init task:
    When I run `bundle exec rake cfn:init`
    Then the exit status should be 0

  Scenario: Validate the templates
    When I run `bundle exec rake cfn:validate`
    Then the output should contain "Validation successful"
    And the exit status should be 0

  Scenario: Upload ansible and cloud formation files to an s3 bucket
    When I run `bundle exec rake cfn:upload`
    Then the output should not contain "ERROR"
    And the exit status should be 0

  Scenario: Create a new environment
    When I run `bundle exec rake cfn:create`
    Then the output should not contain "ERROR"
    And the exit status should be 0

  Scenario: Update a new environment
    When I run `bundle exec rake cfn:update`
    Then the output should not contain "ERROR"
    And the exit status should be 0

  Scenario: Get the ansible run status
    When I run `bundle exec rake cfn:get_ansible_status`
    Then the output should not contain "ERROR"
    And the exit status should be 0

  Scenario: Delete the environment
    When I run `bundle exec rake cfn:delete`
    Then the output should not contain "ERROR"
    And the exit status should be 0

  Scenario: Delete the environment
    When I run `bundle exec rake cfn:create cfn:delete_stack`
    Then the output should not contain "ERROR"
    And the exit status should be 0
