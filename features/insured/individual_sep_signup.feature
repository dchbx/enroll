Feature: Insured Plan Shopping on Individual market
  
  Scenario: New insured user purchases on individual market
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal outside of open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping
    Then Individual should see a form to enter personal information
    When Individual clicks on Save and Exit
    Then Individual resumes enrollment
    Then Individual sees previously saved address
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should see the dependents form
    And Individual clicks on add member button
    And Individual again clicks on add member button
    And I click on continue button on household info form
    When I click the "Married" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    When I click on continue button on group selection page during a sep
    And I select three plans to compare
    And I should not see any plan which premium is 0
    And I select a plan on plan shopping page
    And I click on purchase button on confirmation page
    And I click on continue button to go to the individual home page
    And I should see the individual home page
    Then Individual logs out

  Scenario: Consumer work flow if he did not selects any sep & also not in open enrollment period
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal outside of open enrollment
    Then Individual creates a new HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping
    Then Individual should see a form to enter personal information
    When Individual clicks on Save and Exit
    Then Individual resumes enrollment
    Then Individual sees previously saved address
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should see the dependents form
    And I click on continue button on household info form
    When I click on none of the situations listed above apply checkbox
    And I click on back to my account button
    Then I should land on home page
    And I click on log out link
    Then Individual resumes enrollment
    And I click on sign in existing account
    And I signed in
    Then I should land on home page
    Then Individual logs out

  Scenario: Consumer work flow if he selects sep but not done plan shopping
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal outside of open enrollment
    Then Individual creates a new HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping
    Then Individual should see a form to enter personal information
    When Individual clicks on Save and Exit
    Then Individual resumes enrollment
    Then Individual sees previously saved address
    Then Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    Then Individual should see the dependents form
    And I click on continue button on household info form
    When I click the "Married" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    Then I click on back to my account
    Then I should land on home page
    When I click on log out link
    Then Individual resumes enrollment
    And I click on sign in existing account
    And I signed in
    Then I should land on home page
    Then Individual logs out
