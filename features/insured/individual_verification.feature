Feature: Consumer verification process

  Scenario: Outstanding verification
    Given Individual has not signed up as an HBX user
    * Individual visits the Insured portal during open enrollment
    * Individual creates HBX account
    * I should see a successful sign up message
    * user should see your information page
    * user goes to register as an individual
    * user clicks on continue button
    * user should see heading labeled personal information
    * Individual should click on Individual market for plan shopping
    * Individual should see a form to enter personal information
    * Individual clicks on Save and Exit
    * Individual resumes enrollment
    * Individual click continue button
    * Individual agrees to the privacy agreeement
    * Individual should see identity verification page and clicks on submit
    * Individual should see the dependents form
    * I click on continue button on household info form
    * I click on continue button on group selection page
    * I select a plan on plan shopping page
    * I click on purchase button on confirmation page
    * I click on continue button to go to the individual home page
    * I should see Documents link
    * I click on verification link
    * I should see page for documents verification
    * I upload the file as vlp document
    * I click the upload file button


  Scenario: Consumer with outstanding verification and uploaded documents
    Given a consumer exists
    And the consumer is logged in
    When the consumer visits verification page
    And the consumer should see documents verification page
    Then the consumer can expand the table by clicking on caret sign







