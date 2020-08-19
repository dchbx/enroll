Feature: Passive renewal should be updated when EE updates his current coverage

  Scenario: Employee enters a SEP
    Given Renewing Employer for Soren White exists with active and renewing plan year
      And Employee has past hired on date
      And Employer for Soren White is under open enrollment
      And Soren White already matched and logged into employee portal
      And Soren White has active coverage and passive renewal
      Then Soren White should see active and renewing enrollments
      When Employee click the "Had a baby" in qle carousel
      And Employee select a past qle date
      Then Employee should see confirmation and clicks continue
      Then Employee should see the dependents page
      When Employee clicks Add New Person
      Then Employee should see the new dependent form
      When Employee enters the dependent info of Sorens daughter
      When Employee clicks confirm member
      Then Employee should see 1 dependents
      When Employee clicks continue on family members page
      When Soren White proceed with continue on the group selection page
      Then Soren White should see the list of plans
      When Soren White selects a plan on the plan shopping page
      When Employee clicks on Confirm button on the coverage summary page
      Then Employee clicks back to my account button
      Then Soren While should see active enrollment with his daughter
      And Soren White should see updated renewal with his daughter

  Scenario: Passively Renewed Employee terminates his coverage
    Given Renewing Employer for Soren White exists with active and renewing plan year
      And Employee has past hired on date
      And Employer for Soren White is under open enrollment
      And Soren White already matched and logged into employee portal
      And Soren White has active coverage and passive renewal
      Then Soren White should see active and renewing enrollments
      When Soren White selects make changes on active enrollment
      Then Soren White should see page with SelectPlanToTerminate button
      When Soren White clicks SelectPlanToTerminate button
      Then Soren White selects active enrollment for termination
      When Soren White enters termination reason
      Then Soren White should see termination confirmation
      Then Soren White should not see a passive waiver