Feature: Employee passive renewal should be canceled when Employee waived coverage

  After passive renewal is generated for a renewing employee from previous year plan selection
  if employee chooses to waive coverage, passive renewal should be canceled

  Scenario: Renewing employee waive coverage
    Given Renewing Employer for Soren White exists with active and renewing plan year
      And I set the eligibility rule to first of month following 30 days
      And Employee has past hired on date
      And Employee has past created at date
      And Employer for Soren White is under open enrollment
      And Soren White already matched and logged into employee portal
      And Soren White has active coverage and passive renewal
      Then Soren White should see active and renewing enrollments
      When Soren White clicks "Shop for Plans" on my account page
      When Soren White proceed with continue on the group selection page
      Then Soren White should see the list of plans
      When Soren White selects waiver on the plan shopping page
      When Soren White submits waiver reason
      Then Soren While should see waiver summary page
      When Soren While clicks continue on waiver summary page
      Then Soren White should see "my account" page with waiver and passive renewal should be canceled
