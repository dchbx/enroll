@wip
Feature: Any Person with User account should be able to Edit his information from Manage account tab

  Scenario Outline: Person with User account clicks on Personal Info Section and can see his information
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits manage account
    And person clicks on personal info section
    Then person should see his <role> information


    Examples:
      | role     |
      | Employee |
      | Consumer |
      | Resident |
      | Employer Staff |
      | GA Staff |
      | Broker Staff |

  Scenario Outline: Person with User account clicks on Personal Info Section and edits his information
    Given that a person with <role> exists in EA
    And person with <role> signs in and visits manage account
    And person clicks on personal info section
    And person edits his information
    When person clicks update
    Then person should see the successful message


    Examples:
      | role     |
      | Employee |
      | Consumer |
      | Resident |
      | GA Staff |
      | Employer Staff |
      | Broker Staff |
