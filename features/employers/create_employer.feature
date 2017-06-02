Feature: Create Employer
  In order for Employers to create and manage an account on the HBX for their organization
  In order for Employees to purchase insurance
  An Employer Representative should be able to create an Employer account
  Employer should be able to enter an incorrect plan year
  Employer should be able to add a roster employee with family
  Employer should be able to correct and publish a plan year
  Then
  Employee should be able to create an account, match to their employer and roster family
  Employee should be able to  purchase insurance

    
    Scenario: An Employer Representative has not signed up on the HBX
      Given Employer has not signed up as an HBX user
      When I visit the Employer portal
      Then John Doe creates an HBX account
      Then I should see a successful sign up message
      Then I should click on employer portal
      Then John Doe creates a new employer profile with non_dc_office_location
      When I go to the Profile tab
      When Employer goes to the benefits tab I should see plan year information
      And Employer should see a button to create new plan year
      And Employer should be able to enter plan year, benefits, relationship benefits with high FTE
      And Employer should see a success message after clicking on create plan year button
      When Employer clicks on the Employees tab
      When Employer clicks on the add employee button
      Then Employer should see a form to enter information about employee, address and dependents details
      And Employer should see employer census family created success message
      When Employer goes to the benefits tab
      Then Employer should see the plan year
      When Employer clicks on publish plan year
      Then Employer should see Publish Plan Year Modal with address warnings
      When Employer clicks on the Cancel button
      Then Employer should be on the business info page with warnings
      When Employer updates the address location with correct address
      When Employer goes to the benefits tab
      Then Employer should see the plan year
      When Employer clicks on publish plan year
      Then Employer should see Publish Plan Year Modal with FTE warnings
      When Employer clicks on the Cancel button
      Then Employer should be on the Plan Year Edit page with warnings
      When Employer updates the FTE field with valid input and save plan year
      Then Employer should see a plan year successfully saved message
      And Employer clicks on Edit family button for a census family
      Then Employer should see a form to update the contents of the census employee
      And Employer should see employer census family updated success message
      When Employer goes to the benefits tab I should see plan year information
      Then Employer clicks on publish plan year
      Then Employer should see a published success message
      When Employer logs out

      Given Employee has not signed up as an HBX user
      When I go to the employee account creation page
      Then Patrick Doe creates an HBX account
      #Then Patrick Doe should be logged on as an unlinked employee
      When Employee go to register as an employee
      Then Employee should see the employee search page
      When Employee enters the identifying info of Patrick Doe
      Then Employee should see the matching employee record form
      When Employee accepts the matched employer
      When Employee completes the matched employee form for Patrick Doe
      Then Employee should see the dependents page
      Then Employee should see 1 dependent
      When Employee clicks continue on the dependents page
      Then Employee should see the group selection page
      When Employee clicks continue on the group selection page
      Then Employee should see the plan shopping welcome page
      Then Employee should see the list of plans
      When Employee enters filter in plan selection page
      When Employee enters combined filter in plan selection page
      Then Employee should see the combined filter results
      When Employee enters hsa_compatible filter in plan selection page
      Then Employee should see the hsa_compatible filter results
      When Employee selects a plan on the plan shopping page
      Then Employee should see the coverage summary page
      When Employee clicks on Confirm button on the coverage summary page
      Then Employee should see the receipt page
      Then Employee should see the "my account" page
      And Employee logs out

    Scenario: When fte_count, pte_count and msp_count are blank, CONTINUE button should be disabled
      Given Employer has not signed up as an HBX user
      When I visit the Employer portal
      Then Jack Doe create a new account for employer
      Then I should see a successful sign up message
      Then I should click on employer portal
      Then Jack Doe creates a new employer profile with default_office_location
      When I go to the Profile tab
      When Employer goes to the benefits tab
      And Employer should see a button to create new plan year
      When Employer enters plan year start date
      Then Employer should see disabled button with text continue
      When Employer enters total number of employees
      When Employer clicks continue
      Then Employer should see benefits page
      And Employer logs out
