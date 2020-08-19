Feature: Consumer shops for plan with existing seps

  Scenario: Consumer work flow if he selects existing sep
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
    Then Individual should be on the Help Paying for Coverage page
    Then Individual does not apply for assistance and clicks continue
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
    Then I can click on Shop for Plan button
    And Page should contain existing qle
    Then I can click Shop with existing SEP link
    Then Individual logs out