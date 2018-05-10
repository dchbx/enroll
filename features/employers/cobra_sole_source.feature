@attestation_disabled
Feature: COBRA basic
  Scenario: An Employer is new to the Exchange and needs to enter COBRA enrollees
    Given shop health plans exist for both last and this year
    Given Employer has not signed up as an HBX user
    Given only sole source plans are offered
    When I visit the Employer portal
    Then Jack Doe create a new account for employer
    Then I should see a successful sign up message
    And I select the all security question and give the answer
    When I have submit the security questions
    Then I should click on employer portal
    Then Jack Doe creates a new employer profile with default_office_location
    When I go to the Profile tab
    When Employer goes to the benefits tab I should see plan year information
    And Employer should see a button to create new plan year
    And Employer should be able to enter sole source plan year, benefits, relationship benefits for cobra
    And Employer should see a success message after clicking on create plan year button
    Then Employer uploads an attestation document
    When Employer goes to the benefits tab I should see plan year information
    Then Employer can see the sole source plan information
    Then Employer clicks on publish plan year
    Then Employer should see a published success message without employee

    When I go to MY Health Connector tab
    Then Employer can see the sole source plan information on home tab

    When Employer clicks on the Employees tab
    When Employer clicks to add the first employee
    Then Employer should see a form to enter information about employee, address and dependents details for Jack Cobra
    And Employer should see census employee created success message for Jack Cobra
    And Employer should see the status of cobra_eligible

    When Employer clicks on the Employees tab
    When Employer clicks on the add employee button
    Then Employer should see a form to enter information about employee, address and dependents details for Jack Employee
    And Employer should see census employee created success message for Jack Employee
    When Employer click active employee filter
    Then Employer should see the status of eligible
    Then Employer logs out

    When Jack Cobra visits the employee portal
    When Jack Cobra creates an HBX account
    And I select the all security question and give the answer
    When I have submit the security questions
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Jack Cobra
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Jack Cobra
    When Employee clicks continue on the dependents page
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    When Employee selects a plan on the plan shopping page
    When Employee clicks on Confirm button on the coverage summary page
    Then Jack Cobra should see the receipt page and verify employer contribution for cobra employee
    Then Jack Cobra should see my account page
    Then Jack Cobra logs out

    When Jack Employee visits the employee portal
    When Jack Employee creates an HBX account
    And I select the all security question and give the answer
    When I have submit the security questions
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Jack Employee
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Jack Employee
    When Employee clicks continue on the dependents page
    Then Employee should see the group selection page
    When Employee clicks continue on the group selection page
    Then Employee should see the list of plans
    When Employee selects a plan on the plan shopping page
    When Employee clicks on Confirm button on the coverage summary page
    Then Jack Employee should see the receipt page and verify employer contribution for normal employee
    Then Jack Employee should see my account page
    Then Jack Employee logs out

    When Jack Doe visit the Employer portal
    And Jack Doe login in for employer
    Then Jack Doe should see employer profile page
    When Set Date two months later
    When Employer clicks on the Employees tab
    And Employer should see the status of Cobra Linked
    And Employer should see the status of Employee Role Linked
    When Jack Doe terminate one employee
    Then Employer should see terminate successful msg
    When Employer click terminated employee filter
    Then Employer should see the status of Employment terminated
    When Employer cobra one employee
    Then Employer should see cobra successful msg
    When Employer click all employee filter
    Then Employer should only see the status of Cobra Linked
    Then Employer logs out

    When Jack Employee visits the employee portal
    And Jack Employee login in for employee
    Then Jack Employee should see my account page
    Then Jack Employee should see cobra enrollment on my account page
    Then Jack Employee should see market type on my account page
    Then Jack Employee should not see individual on enrollment title
    Then Set Date back to two months ago
    Then Employee logs out
