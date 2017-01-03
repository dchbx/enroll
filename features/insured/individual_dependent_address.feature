Feature: Insured Plan Shopping on Individual market

  Scenario: New insured user purchases on individual market
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal during open enrollment
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
    Then Individual edits a dependents address
    Then Individual fills in the form
    Then Individual ads address for dependent
    And Individual logs out

  Scenario: New insured user should be on privacy agreeement/verification page on clicking Individual and Family link on respective pages.
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal during open enrollment
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
    When Individual clicks on Individual and Family link should be on privacy agreeement page
    Then Individual agrees to the privacy agreeement
    When Individual clicks on Individual and Family link should be on verification page
    Then Individual should see identity verification page and clicks on submit

