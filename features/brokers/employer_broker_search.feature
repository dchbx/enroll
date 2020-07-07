Feature: Employer terminates borker and hires new broker
  In order for Employer to restrict Broker access to his account
  The Employer should be able to fire previously selected broker

  Background: Broker registration
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    Given there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc
    Given there is a Broker Agency exists for Browns Inc
    Given all permissions are present
    And the broker Jane Goodall is primary broker for Browns Inc
    Given there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And initial employer ABC Widgets has draft benefit application

    Scenario: Employer assigns broker agency
      And staff role person logged in
      And ABC Widgets goes to the brokers tab
      Then Employer should see no active broker
      When Employer clicks on Browse Brokers button
      Then Employer should see broker agencies index view

      When Employer searches broker agency District Brokers Inc
      Then Employer should see broker agency District Brokers Inc

      When Employer searches broker agency Browns Inc
      Then Employer should see broker agency Browns Inc

      When Employer searches primary broker Max Planck
      Then Employer should see broker agency District Brokers Inc

      When Employer searches primary broker Jane Goodall
      Then Employer should see broker agency Browns Inc

      And Employer logs out
