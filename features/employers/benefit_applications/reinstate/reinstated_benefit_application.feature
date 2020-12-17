Feature: When a benefit application gets reinstated the newly created benefit application span will have reistated information display on it.

  Scenario: New hire has enrollment period based on roster entry date
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for active initial employer with health benefits
    Given Qualifying life events are present
    And there is an employer Acme Inc.
    And initial employer Acme Inc. has terminated benefit application
    Given terminated benefit application effective_period updated
    And initial employer Acme Inc. has active benefit application
    And active benefit application is a reinstated benefit application
    And Acme Inc. employer has a staff role
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    Given staff role person logged in
    And Employee has past hired on date
    And Acme Inc. employer visit the Employee Roster
    When Employer goes to the benefits tab
    And Employer see reinstated benefit application
    Then Employer logs out
