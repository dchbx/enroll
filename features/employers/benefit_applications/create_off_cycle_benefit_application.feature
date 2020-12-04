Feature: Ability for employer to create an off-cycle benefit application and allow employees to plan shop

  Background: Setup site, employer, and benefit market catalogs
    Given a CCA site exists with a benefit market
    And benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role

    Scenario: Initial Employer is terminated. Employer is able to create off-cycle benefit application and employees are able to plan shop
      Given Qualifying life events are present
      And initial employer ABC Widgets has active benefit application
      And there is a census employee record and employee role for Patrick Doe for employer ABC Widgets
      And census employee Patrick Doe has a past DOH
      And employees for employer ABC Widgets have selected a coverage
      Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      When the user clicks Action for that Employer
      And the user clicks the Plan Years button
      Then the user will select benefit application to terminate
      When the user clicks Actions for current benefit application
      When the user clicks Actions for that benefit application
      Then the user will see Terminate button
      When the user enters any_day and other details for voluntary termination
      When user clicks submit button
      Then user should see termination successful message
      And user logs out
      And staff role person logged in
      And update rating area
      When ABC Widgets is logged in and on the home page
      And staff role person clicked on benefits tab
      Then employer should see benefit application in termination pending state
      And employer should see Add Plan Year link
      Then employer should see add plan year button
      And employer clicks Add Plan Year link
      And employer clicks OK in warning modal
      And employer filled all the fields on benefit application form
      And employer clicked on continue button
      Then employer should see form for benefit package
      And employer filled all the fields on benefit package form for off-cycle application
      And employer selected by metal level plan offerings
      Then employer should see gold metal level type
      And employer clicked on gold metal level
      Then employer should see create plan year button disabled
      And employer selected 100 contribution percent for the application
      Then employer should see your estimated montly cost
      And employer should see that the create plan year is true
      And employer clicks Create Plan Year
      And staff role person clicked on employees tab
      And staff role person clicks on employees link
      And staff role person clicks on employee Patrick Doe
      Then the user should see a dropdown for Off Plan Year benefit package
      And census employee Patrick Doe has benefit group assignment of the off cycle benefit application
      And staff role person clicked on benefits tab
      When Employer clicks on publish plan year
      And user logs out
      And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
      When Patrick Doe clicks "Shop for Plans" on my account page
      Then Employee should see the group selection page
      When Employee clicks continue on the group selection page
      Then Employee should see the list of plans
      When Employee selects a plan on the plan shopping page
      When Employee clicks on Confirm button on the coverage summary page
      Then Employee should see the receipt page
      Then Employee should see the "my account" page
      And employee Patrick Doe of employer ABC Widgets most recent HBX Enrollment should be under the off cycle benefit application

    Scenario: Renewal Employer is terminated. Employer is able to create off-cycle benefit application and employees are able to plan shop
      Given Qualifying life events are present
      And renewal employer ABC Widgets has active and renewal enrollment_open benefit applications
      And there is a census employee record and employee role for Patrick Doe for employer ABC Widgets
      And census employee Patrick Doe has a past DOH
      And employees for employer ABC Widgets have selected a coverage
      Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      When the user clicks Action for that Employer
      And the user clicks the Plan Years button
      Then the user will select benefit application to terminate
      When the user clicks Actions for current benefit application
      When the user clicks Actions for that benefit application
      Then the user will see Terminate button
      When the user enters any_day and other details for voluntary termination
      When user clicks submit button
      Then user should see termination successful message
      And user logs out
      And staff role person logged in
      And update rating area
      When ABC Widgets is logged in and on the home page
      And staff role person clicked on benefits tab
      Then employer should see benefit application in termination pending state
      And employer should see Add Plan Year link
      Then employer should see add plan year button
      And employer clicks Add Plan Year link
      And employer clicks OK in warning modal
      And employer filled all the fields on benefit application form
      And employer clicked on continue button
      Then employer should see form for benefit package
      And employer filled all the fields on benefit package form for off-cycle application
      And employer selected by metal level plan offerings
      Then employer should see gold metal level type
      And employer clicked on gold metal level
      Then employer should see create plan year button disabled
      And employer selected 100 contribution percent for the application
      Then employer should see your estimated montly cost
      And employer should see that the create plan year is true
      And employer clicks Create Plan Year
      And staff role person clicked on employees tab
      And staff role person clicks on employees link
      And staff role person clicks on employee Patrick Doe
      Then the user should see a dropdown for Off Plan Year benefit package
      And census employee Patrick Doe has benefit group assignment of the off cycle benefit application
      And staff role person clicked on benefits tab
      When Employer clicks on publish plan year
      And user logs out
      And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
      When Patrick Doe clicks "Shop for Plans" on my account page
      Then Employee should see the group selection page
      When Employee clicks continue on the group selection page
      Then Employee should see the list of plans
      When Employee selects a plan on the plan shopping page
      When Employee clicks on Confirm button on the coverage summary page
      Then Employee should see the receipt page
      Then Employee should see the "my account" page
      And employee Patrick Doe of employer ABC Widgets most recent HBX Enrollment should be under the off cycle benefit application
      