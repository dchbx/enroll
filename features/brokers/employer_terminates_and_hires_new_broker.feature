Feature: Employer terminates borker and hires new broker
  In order for Employer to restrict Broker access to his account
  The Employer should be able to fire an existing broker and hire new broker if needed

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
    And employer ABC Widgets hired broker Jane Goodall from Browns Inc

    Scenario: Employer terminates broker agency and hires new agency
      And staff role person logged in
      And ABC Widgets goes to the brokers tab
      Then Employer should see broker Jane Goodall and agency Browns Inc active for the employer
      When Employer terminates broker
      Then Employer should see broker terminated message
      When Employer clicks on the Brokers tab
      Then Employer should see no active broker
      When Employer clicks on Browse Brokers button
      Then Employer should see broker agencies index view
      When Employer searches broker agency District Brokers Inc
      Then Employer should see broker agency District Brokers Inc
      When Employer clicks select broker button
      Then Employer should see confirm modal dialog box
      When Employer confirms broker selection
      Then Employer should see broker selected successful message
      When Employer clicks on the Brokers tab
      Then Employer should see broker Max Planck and agency District Brokers Inc active for the employer
      And Employer logs out
