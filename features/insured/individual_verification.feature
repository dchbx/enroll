Feature: Consumer verification process

  Scenario: Outstanding verification
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal during open enrollment
    And Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    And user clicks on continue button
    Then user should see heading labeled personal information
    And Individual should click on Individual market for plan shopping
    Then Individual should see a form to enter personal information
    When Individual clicks on Save and Exit
    Then Individual resumes enrollment
    When Individual click continue button
    And Individual agrees to the privacy agreeement
    Then Individual should see identity verification page and clicks on submit
    And Individual should see the dependents form
    When I click on continue button on household info form
    And I click on continue button on group selection page
    When I select a plan on plan shopping page
    And I click on purchase button on confirmation page
    And I click on continue button to go to the individual home page
    Then I should see Documents link
    When I click on verification link
    Then I should see page for documents verification
    When I upload the file as vlp document
    Then I click the upload file button


  Scenario: Consumer with outstanding verification and uploaded documents
    Given a consumer exists
    And the consumer is logged in
    When the consumer visits verification page
    And the consumer should see documents verification page
    Then the consumer can expand the table by clicking on caret sign
    And Consumer does not see FedHub details table







