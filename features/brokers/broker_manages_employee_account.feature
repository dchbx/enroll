Feature: Broker Manages Employee Account
  In order to help Employees with plan shopping, brokers can access their employers employees accounts
  The Broker should be able to do plan shopping for employees

  Background: Broker registration
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    Given there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    Given there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And employer ABC Widgets hired broker Max Planck from District Brokers Inc
    And initial employer ABC Widgets has enrollment_open benefit application
    And there is a census employee record for Patrick Doe for employer ABC Widgets

  Scenario: Broker manages employer account
    When I go to the employee account creation page
    When Patrick Doe creates an HBX account
    When Patrick Doe goes to register as an employee
    Then Patrick Doe should see the employee search page
    When Employee enter the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Patrick Doe accepts the matched employer
    Then Employee completes the matched employee form for Patrick Doe
    And I log out

    When Max Planck logs on to the Broker Agency Portal
    And Primary Broker clicks on the Families tab
    Then Primary Broker should see Patrick Doe as family and click on name
    Then Primary Broker should see Patrick Doe account
    # Then Primary Broker is on the consumer home page
    # Then Primary Broker shops for plans
    # Then Primary Broker sees covered family members
    # Then Primary Broker should see the list of plans
    # Then Primary Broker selects a plan on the plan shopping page
    # And Primary Broker clicks on purchase button on the coverage summary page
    # And Primary Broker should see the receipt page
    Then Primary Broker logs out