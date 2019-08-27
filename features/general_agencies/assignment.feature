Feature: Broker Assigns a General Agency to an Employer

Background: General Agency registration
  Given a CCA site exists with a benefit market
  Given benefit market catalog exists for draft initial employer with health benefits
  Given there is a Broker Agency exists for Browns Inc
  And the broker Jane Goodall is primary broker for Browns Inc
  Given there is an employer ABC Widgets
  And ABC Widgets employer has a staff role
  And initial employer ABC Widgets has draft benefit application
  Given there is a General Agency exists for District Agency Inc
  And the staff Primary Ga is primary ga staff for District Agency Inc

  Scenario: A Broker Assigns a General Agency to an Employer
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

    When Jane Goodall logs on to the Broker Agency Portal
    Then the broker should see the home of broker
    When the broker visits their Employers page
    And selects the general agency from dropdown for the employer
    Then the broker should see assign successful message
    When the broker visits their Employers page
    Then the employer is assigned to general agency
    Then the broker logs out

    When Primary Ga logs on to the General Agency Portal
    Then the ga should see the home of ga
    When the ga visits their Employers page
    Then the ga should see the employer
    When the ga click the name of employer
    Then the ga should see the home of employer
    When the ga clicks on the Brokers tab
    Then the ga should see the broker
    When the ga click the back link
    Then the ga should see the home of ga

  Scenario: A Broker have the ability to assign default GA for any employers
    When Jane Goodall logs on to the Broker Agency Portal
    Then the broker should see the home of broker
    When the broker visits their general agencies page
    Then the broker should see the Clear Default GA in the list of general agencies
    When the broker set default ga
    Then the broker should see default ga msg
    Then the broker logs out

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

    When Primary Ga logs on to the General Agency Portal
    Then the ga should see the home of ga
    When the ga visits their Employers page
    Then the ga should see the employer

  Scenario: If broker already assigned some ERs, while the Broker remove his default GA, that particular GA should automatically loss the permission to those ERs
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

    When Jane Goodall logs on to the Broker Agency Portal
    Then the broker should see the home of broker
    When the broker visits their general agencies page
    Then the broker should see the Clear Default GA in the list of general agencies
    When the broker set default ga
    Then the broker should see default ga msg
    Then the broker should see the Clear Default GA in the list of general agencies
    When the broker click the link of clear default ga
    Then the broker should see no default ga msg
    Given call change default ga subscriber for ga1 with pre default ga id
    When the broker visits their Employers page
    Then the employer will not be assigned that general agency
    Then the broker logs out
