Feature: Non-congressional EE adding non-diabled 26 years old dependent

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    Given Qualifying life events are present
    And there is an employer AB Widgets
    And AB Widgets employer has a staff role
    And renewal employer AB Widgets has active and renewal enrollment_open benefit applications
    And this employer renewal application is under open enrollment

  Scenario: Employee enters a SEP, adds non-diabled 26 years old dependent and purchases plan
    Given there exists Patrick Doe employee for employer AB Widgets
    And employee Patrick Doe has current hired on date
    And employee Patrick Doe already matched with employer AB Widgets and logged into employee portal
    And Patrick Doe has active coverage and passive renewal
    When employee clicks "Shop for Plans" on my account page
    And employee clicks continue on the group selection page
    And employee sees the list of plans
    And employee selects a plan on the plan shopping page
    And employee clicks on Confirm button on the coverage summary page
    Then employee should see the receipt page
    And employee should see the "my account" page
    When employee clicks "Losing other health insurance" link in the qle carousel
    And employee selects a current qle date
    And employee sees the QLE confirmation message and clicks on continue
    And employee clicks Add Member
    And Employee should not see the Ageoff Exclusion checkbox
    And employee sees the new dependent form
    And employee enters the info of his dependent wife
    And employee clicks confirm member
    Then employee should see 1 dependent
    When employee clicks continue on group selection page for dependents
    And employee clicks Shop for new plan button
    And employee sees the list of plans
    And employee selects a plan on the plan shopping page
    And employee clicks on Confirm button on the coverage summary page
    And employee clicks back to my account button
    Then employee should see his active enrollment including his wife
    When Employee should click on Manage Family button
    And Employee should click on the Personal Tab link
    Then Employee should not see the Ageoff Exclusion checkbox
