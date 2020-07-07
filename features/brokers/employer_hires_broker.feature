Feature: Employer hires borker
  In order for Broker to help Employers manage their accounts
  The Employer should be able to browse and select the Primary Broker as their Broker

  Background: Broker registration
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    Given there is a Broker Agency exists for District Brokers Inc
    Given all permissions are present
    And the broker Max Planck is primary broker for District Brokers Inc
    Given there is a Broker Agency exists for Browns Inc
    And the broker Jane Goodall is primary broker for Browns Inc
    Given there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And initial employer ABC Widgets has draft benefit application

    Scenario: Employer assigns broker agency
      And staff role person logged in
      And ABC Widgets goes to the brokers tab
      Then Employer should see no active broker
      When Employer click on Browse Brokers button
      Then Employer should see broker agencies index view
      When Employer searches broker agency Browns Inc
      Then Employer should see broker agency Browns Inc
      When Employer clicks select broker button
      Then Employer should see confirm modal dialog box
      When Employer confirms broker selection
      Then Employer should see broker selected successful message
      When Employer clicks on the Brokers tab
      Then Employer should see broker Jane Goodall and agency Browns Inc active for the employer
      And Employer logs out
