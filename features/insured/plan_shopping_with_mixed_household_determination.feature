Feature: plan shopping with mixed household determination

  Background: Consumer work flow while plan shopping for mixed household determinations
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal during open enrollment
    Then Individual creates a new HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should see a form to enter personal information
    Then Individual sees previously saved address
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should be on the Help Paying for Coverage page
    Then Individual does not apply for assistance and clicks continue
    Then Individual should see the dependents form
    And Individual clicks on add member button
    And Individual clicks on confirm member
    When csr plans exists in db
    Then I click on continue button on household info form

  @wip
  Scenario: plan shopping with mixed pdc eligible taxhoushold members
    Given all plan shopping are of mixed determination
    And I click on continue button on group selection page
    Then the page should not have any csr plans
    And Individual logs out

  Scenario: plan shopping with all eligible taxhoushold members
    Given every individual is eligible for Plan shopping for CSR plans
    And I click on continue button on group selection page
    Then the page should have csr plans
    And Individual logs out

  @wip
  Scenario: plan shopping with all eligible taxhoushold members shops for CSR plan
    Given every individual is eligible for Plan shopping for CSR plans
    And I click on continue button on group selection page
    Then the page should have csr plans
    And selects a csr plan
    Then the page should redirect to thankyou page
    And Individual logs out

  @wip
  Scenario: plan shopping with all eligible taxhoushold members shops for non CSR plan
    Given every individual is eligible for Plan shopping for CSR plans
    When the db has standard plans
    And I click on continue button on group selection page
    And selects a non csr plan
    Then the page should open a model pop-up for confirmation
    Then user clicks close button
    And Individual logs out
