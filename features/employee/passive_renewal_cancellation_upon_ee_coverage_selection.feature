Feature: Employee passive renewal should be canceled when Employee selected coverage

  After a passive renewal if employee makes a plan selection, passive renewal should be canceled

  Scenario: Renewing employee makes plan selection
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
      When Soren White selects a plan on the plan shopping page
      Then Soren White should see coverage summary page with renewing plan year start date as effective date
      Then Soren White should see the receipt page with renewing plan year start date as effective date
      Then Soren White should see "my account" page with new enrollment and passive renewal should be canceled
