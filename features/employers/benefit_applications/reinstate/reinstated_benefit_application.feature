Feature: When a benefit application gets reinstated the newly created benefit application span will have reinstated indicator on it.

  Scenario: when Admin goes to employer portal should see reinstated text for reinstated benefit application
    Given the Reinstate feature configuration is enabled
    And a CCA site exists with a benefit market
    And benefit market catalog exists for active initial employer with health benefits
    And there is an employer ABC Widgets
    And initial employer ABC Widgets has active benefit application
    And initial employer ABC Widgets application terminated
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will see the Plan Years button
    Then the user will select benefit application to reinstate
    When the user clicks Actions for that benefit application
    Then the user will see Reinstate button
    When Admin clicks on Reinstate button
    Then Admin will see Reinstate Start Date for terminated benefit application
    And Admin will see transmit to carrier checkbox
    When Admin clicks on Submit button
    Then Admin will see confirmation pop modal
    When Admin clicks on continue button for reinstating benefit_application
    Then Admin will see a Successfull message
    And the user is on the Employer Index of the Admin Dashboard
    When the Admin click on the employer ABC Widgets
    Then Admin lands on employer ABC Widgets profile
    When Admin go to the benefits tab
    Then Admin should see reinstated indicator on benefit application
    And Admin logs out
