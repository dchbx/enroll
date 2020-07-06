Feature: Conversion employees can purchase coverage only through renewing plan year
  In order to make employees purchase coverage only using renewal plan year
  Employee should be blocked from buying coverage under off-exchange plan year

  Scenario: New Hire should not get effective date before renewing plan year start date
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    Given Qualifying life events are present
    And there is an employer ACME Widgets, Inc.
    And renewal employer ACME Widgets, Inc. has imported and renewal enrollment_open benefit applications
    And ACME Widgets, Inc. employer has a staff role
    And there is a census employee record for Patrick Doe for employer ACME Widgets, Inc.
    
    Given staff role person logged in
    And ACME Widgets, Inc. employer visit the Employee Roster
    Then Employer logs out
    And Employee has not signed up as an HBX user
    And Patrick Doe visits the employee portal
    When Patrick Doe creates an HBX account
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer

    When Employee completes the matched employee form for Patrick Doe
    And Employee sees the Household Info: Family Members page and clicks Continue
    And Employee sees the Choose Coverage for your Household page and clicks Continue
    And Employee selects the first plan available
    And Employee clicks Confirm
    And Employee sees the Enrollment Submitted page and clicks Continue

    Then Employee Patrick Doe should see their plan start date on the page

  Scenario: New Hire can't buy coverage before open enrollment of renewing plan year through Shop for Plans
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer ABC Widgets
    And renewal employer ABC Widgets has imported and renewal enrollment_open benefit applications

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has current hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And census employee Patrick Doe new_hire_enrollment_period is greater than date of record

    When Employee clicks "Shop for Plans" on my account page
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page

    Then Patrick Doe should see "You're not yet eligible under your employer-sponsored benefits" error message

  Scenario: New Hire can't buy coverage before open enrollment of renewing plan year through New Hire badge
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer ABC Widgets
    # And ABC Widgets employer has a staff role
    And renewal employer ABC Widgets has imported and renewal enrollment_open benefit applications

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has current hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And census employee Patrick Doe new_hire_enrollment_period is greater than date of record

    When Employee clicks on New Hire Badge
    When Employee clicks continue on the group selection page

    Then Patrick Doe should see "You're not yet eligible under your employer-sponsored benefits" error message

  Scenario: New Hire can't buy coverage under off-exchange plan year using QLE
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    Given Qualifying life events are present
    And there is an employer ABC Widgets
    And renewal employer ABC Widgets has imported and renewal enrollment_open benefit applications
    
    Given there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has current hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    And census employee Patrick Doe new_hire_enrollment_period is greater than date of record
    When Employee click the "Married" in qle carousel
    And Employee select a past qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page

    Then Patrick Doe should see "You're not yet eligible under your employer-sponsored benefits" error message

  Scenario: New Hire can buy coverage during open enrollment of renewing plan year
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer ABC Widgets
    # And ABC Widgets employer has a staff role
    And renewal employer ABC Widgets has imported and renewal enrollment_open benefit applications

    Given there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has current hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal


     When Employee clicks on New Hire Badge
     When Employee clicks continue on the group selection page
     Then Employee should see the list of plans
     # And I should not see any plan which premium is 0
     When Employee selects a plan on the plan shopping page
     When Employee clicks on Confirm button on the coverage summary page
     And Employee sees Enrollment Submitted and clicks Continue

     Then Patrick Doe should see enrollment on my account page
  
  # Is this needed?
  # Scenario: Existing Employee should not get effective date before renewing plan year start date
    # Given Conversion Employer for Soren White exists with active and renewing plan year
      # And Employee has not signed up as an HBX user
      # And Soren White visits the employee portal
      # When Soren White creates an HBX account
      # And I select the all security question and give the answer
      # When I have submitted the security questions
      # And I select the all security question and give the answer
      # When I have submitted the security questions
      # When Employee goes to register as an employee
      # Then Employee should see the employee search page
      # When Employee enters the identifying info of Soren White
      # Then Employee should see the matched employee record form
      # Then Employee Soren White should have the renewing plan year start date as earliest effective date
      # Then Employee Soren White should not see earliest effective date on the page

  # These is essentially the same scenarios as those on lines 35 and 52
  # Scenario: Existing Employee can't buy coverage before open enrollment of renewing plan year
      # Given Conversion Employer for Soren White exists with active and renewing plan year
      # And Employer for Soren White published renewing plan year
      # And Soren White already matched and logged into employee portal
      # When Employee clicks "Shop for Plans" on my account page
      # When Employee clicks continue on the group selection page
      # Then Soren White should see "open enrollment not yet started" error message

  # This is essentially the same scenario as the one on line 70
  # Scenario: Existing Employee can't buy coverage under off-exchange plan year using QLE
    # Given Conversion Employer for Soren White exists with active and renewing plan year
    # And Employer for Soren White published renewing plan year
    # And Soren White already matched and logged into employee portal
    # When Employee click the "Married" in qle carousel
    # And Employee select a past qle date
    # Then Employee should see confirmation and clicks continue
    # Then Employee should see family members page and clicks continue
    # Then Employee should see the group selection page
    # When Employee clicks continue on the group selection page
    # Then Soren White should see "open enrollment not yet started" error message

  Scenario: Existing Employee can buy coverage during open enrollment of renewing plan year using QLE
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_closed renewal employer with health benefits
    Given Qualifying life events are present
    And there is an employer ABC Widgets
    And renewal employer ABC Widgets has imported and renewal enrollment_open benefit applications
    
    Given there exists Patrick Doe employee for employer ABC Widgets
    And employee Patrick Doe has current hired on date
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    When Employee click the "Losing other health insurance" in qle carousel
    And Employee select a current qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page

    Then Employee should see the list of plans
    When Employee selects a plan on the plan shopping page
    When Employee clicks on Confirm button on the coverage summary page
    And Employee sees Enrollment Submitted and clicks Go to My Account

    Then Patrick Doe should see enrollment on my account page start date as effective date

  # This should be covered on line 91
  # Scenario: Existing Employee can buy coverage during open enrollment of renewing plan year
      # Given Conversion Employer for Soren White exists with active and renewing plan year
      # And Employer for Soren White is under open enrollment
      # And Soren White already matched and logged into employee portal
      # When Employee clicks "Shop for Plans" on my account page
      # When Employee clicks continue on the group selection page
      # Then Employee should see the list of plans
      # And I should not see any plan which premium is 0
      # When Employee selects a plan on the plan shopping page
      # Then Soren White should see coverage summary page with renewing plan year start date as effective date
      # Then Soren White should see the receipt page with renewing plan year start date as effective date
      # Then Employee should see "my account" page with enrollment

#  Scenario: Existing Employee can buy coverage from multiple employers during open enrollment of renewing plan year
#
#    Given a CCA site exists with a benefit market
#    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
#    And there is an employer ABC Widgets
#    And renewal employer ABC Widgets has imported and renewal enrollment_open benefit applications
#    Given there is a census employee record for Patrick Doe for employer ABC Widgets
#
#    And there is an employer ACME Inc
#    And employer ACME Inc has imported and renewing enrollment_open benefit applications
#    Given there is a census employee record for Patrick Doe for employer ACME Inc
#
#    And census employee records for Patrick Doe have current hired on date for each employers
#    And Patrick Doe matches all employee roles to employers and is logged in
#
#    Then Patrick Doe should see the employee privacy text
#    When Patrick Doe enters the identifying info of Patrick Doe
#    And Patrick Doe sees the option to enroll for all employers
#    When Patrick Doe accepts the matched employer
#    When Employee completes the matched employee form for Patrick Doe
#    And Employee sees the Household Info: Family Members page and clicks Continue
#    And employee visits the Employee Portal page
#
#    And Patrick Doe has New Hire Badges for all employers
#    When Patrick Doe click the first button of new hire badge
#
#    Then Employee should see the group selection page
#    When Employee clicks continue on the group selection page
#    Then Employee should see the plan shopping welcome page
#    Then Employee should see the list of plans
#    Then employee should see text for employer ABC Widgets
#    When Employee selects a plan on the plan shopping page
#    Then Employee should see the coverage summary page
#    Then employee should see text for employer ABC Widgets
#    When Employee clicks on Confirm button on the coverage summary page
#    Then employee should see text for employer ABC Widgets
#    Then Employee should see the receipt page
#    Then Employee should see the "my account" page
#
#    When Patrick Doe click the button of new hire badge for 2st ER
#
#    Then Employee should see the group selection page
#    When Employee clicks continue on the group selection page
#    Then Employee should see the plan shopping welcome page
#    Then Employee should see the list of plans
#    Then employee should see text for employer ACME Inc
#    When Employee selects a plan on the plan shopping page
#    Then Employee should see the coverage summary page
#    Then employee should see text for employer ACME Inc
#    When Employee clicks on Confirm button on the coverage summary page
#    Then employee should see text for employer ACME Inc
#    Then Employee should see the receipt page
#    Then Employee should see the "my account" page