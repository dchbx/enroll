Feature: CSR finishes shopping for Individual
  Scenario: New insured user purchases on individual market
    Given Individual has not signed up as an HBX user
      When a CSR exists
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
      Then Individual asks for help
      Then Individual logs out
      Then Devops can verify session logs
      When CSR logs on to the HBX portal
      Then CSR should see the Agent Portal
      Then CSR should click on the Inbox tab
      Then CSR opens the most recent Please Contact Message
      Then CSR clicks on Resume Application via phone
      Then CSR agrees to the privacy agreeement
      Then CSR should see identity verification page and clicks on submit
      Then CSR should see the dependents form
      And I click on the header link to return to CSR page
      Then CSR should see the Agent Portal
      Then CSR should click on the Families tab
      Then CSR clicks on New Consumer Paper Application
      Then CSR starts a new enrollment
      Then CSR logs out

