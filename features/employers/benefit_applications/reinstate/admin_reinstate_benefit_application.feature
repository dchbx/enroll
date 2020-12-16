Feature: As an admin user I should have the ability to click reinstate button on Employer datatable

  Scenario Outline: Admin clicks reinstate button under planyear dropdown for <aasm_state> benefit_application
    Given the Reinstate feature configuration is enabled
    And a CCA site exists with a benefit market
    And benefit market catalog exists for <aasm_state> initial employer with health benefits
    And there is an employer ABC Widgets
    And initial employer ABC Widgets has <aasm_state> benefit application
    And initial employer ABC Widgets has updated <aasm_state> effective period for reinstate
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will see the Plan Years button
    Then the user will select benefit application to reinstate
    When the user clicks Actions for that benefit application
    Then the user will see Reinstate button
    When Admin clicks on Reinstate button
    Then Admin will see Reinstate Start Date for <aasm_state> benefit application
    And Admin will see transmit to carrier checkbox
    When Admin clicks on Submit button
    Then Admin will see confirmation pop modal
    When Admin clicks on continue button for reinstating benefit_application
    Then Admin will see a Successfull message
    And user logs out

  Examples:
    |    aasm_state       |
    |    terminated       |
    | termination_pending |
    | retroactive_cancel  |
    |     canceled        |
