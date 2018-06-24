Feature: Insured Plan Shopping on Individual market

  Background:
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal during open enrollment
    Then Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then Individual logs out

  Scenario: New insured user purchases on individual market
    Given Individual resumes enrollment
    And Individual click on sign in existing account
    And I signed in
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
    When Individual clicks on Save and Exit
    Then Individual resumes enrollment
    Then Individual sees previously saved address
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should see the dependents form
    And Individual clicks on add member button
    And Individual again clicks on add member button #TODO re-write this step
    And I click on continue button on household info form
    And I click on continue button on group selection page
    And I select three plans to compare
    And I should not see any plan which premium is 0
    And I select a plan on plan shopping page
    And I click on purchase button on confirmation page
    And I click on continue button to go to the individual home page
    And I should see the individual home page
    When I click the "Married" in qle carousel
    And I select a future qle date
    Then I should see not qualify message
    When I click the "Married" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    When I click on continue button on household info form
    And I click on "shop for new plan" button on household info page
    And I select a plan on plan shopping page
    And I click on purchase button on confirmation page
    When I click on continue on qle confirmation page
    And I should see the individual home page
    Then Individual logs out

  Scenario: Individual should not see document errors when not applying for coverage.
    Given Individual resumes enrollment
    And Individual click on sign in existing account
    And I signed in
    Then Individual should see heading labeled personal information
    Then Individual should see a form to enter personal information
    Then Individual selects eligible immigration status
    And Individual selects not applying for coverage
    When Individual clicks on continue button
    Then Individual should not see error message Document type cannot be blank
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual logs out

  Scenario: Individual should see document errors when proceeds without uploading document.
    Given Individual resumes enrollment
    And Individual click on sign in existing account
    And I signed in
    Then Individual should see heading labeled personal information
    Then Individual should see a form to enter personal information
    Then Individual selects eligible immigration status
    And Individual selects applying for coverage
    When Individual clicks on continue button
    Then Individual should see error message Document type cannot be blank
    Then Individual logs out

  Scenario: Dependents should see document errors when proceeds without uploading document.
    Given Individual resumes enrollment
    And Individual click on sign in existing account
    And I signed in
    Then Individual should see heading labeled personal information
    Then Individual should see a form to enter personal information
    When Individual clicks on continue button
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should see the dependents form
    And Individual clicks on add member button
    And Individual edits dependent
    And Dependent selects applying for coverage
    And Dependent selects eligible immigration status
    And Individual clicks on confirm member
    Then Dependent should see error message Document type cannot be blank

  Scenario: Dependents should not see document errors when not applying for coverage.
    Given Individual resumes enrollment
    And Individual click on sign in existing account
    And I signed in
    Then Individual should see heading labeled personal information
    Then Individual should see a form to enter personal information
    When Individual clicks on continue button
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should see the dependents form
    And Individual clicks on add member button
    And Individual edits dependent
    And Dependent selects eligible immigration status
    And Dependent selects not applying for coverage
    And Individual clicks on confirm member
    Then Dependent should not see error message Document type cannot be blank
