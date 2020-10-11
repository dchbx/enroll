Feature: Broker Manages Employer Account
  In order to help Employer, brokers can access their employers accounts
  The Broker should be able to set up application and roster for the employer

  Background: Broker registration
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    Given there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    Given there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And initial employer ABC Widgets has draft benefit application
    And employer ABC Widgets hired broker Max Planck from District Brokers Inc

  Scenario: Broker manages employer account
    When Max Planck logs on to the Broker Agency Portal
    And Primary Broker clicks on the Employers tab
    Then Primary Broker should see Employer ABC Widgets and click on legal name
    Then Primary should see the Employer ABC Widgets page as Broker
    When Primary Broker clicks on the Benefits tab
    And Primary Broker publishes the benefit application
    Then Primary Broker should see a published success message without employee
    When Primary Broker clicks on the Employees tab
    Then Primary Broker clicks on the add employee button
    Then Primary Broker creates Broker Assisted as a roster employee
    Then Primary Broker sees employer census family created
    Then Primary Broker logs out