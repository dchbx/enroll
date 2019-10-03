Feature: As an HBX Admin User I can access the QLE Wizard management wizard
  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given all permissions are present
    And that a user with a HBX staff role with HBX staff subrole exists and is logged in
  
  # TODO: These files need to be updated to include questions and responses creation/edit steps
  Scenario: HBX Staff with Super Admin subroles can access and manage the QLE Wizard page
    Given the user is on the Main Page
    When user clicks on the Admin dropdown
    And the user clicks on the Manage QLEs dropdown
    Then the user should see the QLE Kind Wizard

  Scenario: HBX Staff with Super Admin subroles can create a custom QLE Kind
    Given the user is on the Main Page
    When user clicks on the Admin dropdown
    And the user clicks on the Manage QLEs dropdown
    And the user selects Create a Custom QLE and clicks submit
    When the user fills out the new QLE Kind form for Got a New Dog event and clicks submit
    Then user should see message QLE Kind Got a New Dog has been sucessfully created
    And the QLE Kind Got a New Dog should have the proper attributes the user selected in the create form

  Scenario: HBX Staff with Super Admin subroles can edit a custom QLE Kind
    Given qualifying life event kind Got a New Dog present for shop market
    And qualifying life event kind Got a New Dog has custom qle question and accepted response present
    And qualifying life event kind Got a New Dog is not active
    Given the user is on the Main Page
    When user clicks on the Admin dropdown
    And the user clicks on the Manage QLEs dropdown
    And the user selects Modify Existing QLE, Market Kind, and first QLE Kind and clicks submit
    And the user cannot edit the market kind or title of the QLE Kind Got a New Dog
    When the user fills out the edit QLE Kind form for Got a New Dog event and clicks submit
    Then user should see message QLE Kind Got a New Dog has been sucessfully updated

  Scenario: HBX Staff with Super Admin sees error message if edit form not fully completed
    Given qualifying life event kind Got a New Dog present for shop market
    And qualifying life event kind Got a New Dog is not active
    Given the user is on the Main Page
    When user clicks on the Admin dropdown
    And the user clicks on the Manage QLEs dropdown
    And the user selects Modify Existing QLE, Market Kind, and first QLE Kind and clicks submit
    When the user fills out only partially the edit QLE Kind form for Got a New Dog event
    # TODO: This doesn't seem to be working properly on edit
    # And the user sees a message that the fields are required
    And the user clicks the Update QLE Kind button
    Then user should see message Unable to update Qualifying Life Event Kind

  Scenario: HBX Staff with Super Admin subroles does not see active custom QLE Kind available to edit
    Given qualifying life event kind Got a New Dog present for shop market
    And qualifying life event kind Got a New Dog is active
    Given the user is on the Main Page
    When user clicks on the Admin dropdown
    And the user clicks on the Manage QLEs dropdown
    When the user selects Modify Existing QLE
    Then the user should not see an option to select Shop Market Kind QLE Kinds

  Scenario: HBX Staff with Super Admin subroles can deactivate a custom QLE Kind
    Given qualifying life event kind Got a New Dog present for individual market
    And the QLE Kind Got a New Dog has no end_on
    And the user visits the deactivate Qualifying Life Event Kind page for Got a New Dog QLE Kind
    When the user fills out the deactivate QLE Kind form for Got a New Dog event and clicks submit
    Then user should see message QLE Kind Got a New Dog has been sucessfully deactivated
    And the QLE Kind Got a New Dog record should be updated with an end_on date
  
  Scenario: HBX Staff with Super Admin subroles does not see option to deactivate a QLE Kind set for deactivation
    Given qualifying life event kind Had a New Dog present for individual market
    And qualifying life event kind Had a New Dog has end_on date set to 11/01/2020
    Given the user is on the Main Page
    When user clicks on the Admin dropdown
    And the user clicks on the Manage QLEs dropdown
    When the user selects Deactivate Existing QLE
    Then the user should not see an option to select Shop Market Kind QLE Kinds

  # TODO: Add a scenario to test errors being thrown for form not being fully completed
  Scenario: HBX Staff with Super Admin subroles can create a custom QLE Kind visible to customer and then use it to enroll family
    # Given the user is on the Main Page
    # And the user goes to the Config Page
    # And the user clicks the Manage QLE link
    # And the user selects Create a Custom QLE and clicks submit
    # When the user fills out the new QLE Kind form for Got a New Dog event and clicks submit
    # Then user should see message QLE Kind Got a New Dog has been sucessfully created
    # Then user logs out
    ## Taken from admin_sep_selection.feature
    ## Assure that the last QLE kind created is present
    # And qualifying life event kind Got a New Dog present for individual market
    # And qualifying life event kind Got a New Dog for individual market created by user in QLE Wizard present
    # And all qualifying life event kinds are visible to customer
    # And all qualifying life event kinds are active
    ## Individual sign up
    # Given Individual has not signed up as an HBX user
    # When Individual visits the Insured portal during open enrollment
    # Then Individual creates HBX account
    # Then I should see a successful sign up message
    # And user should see your information page
    # When user goes to register as an individual
    # Then user clicks on continue button
    # Then user should see heading labeled personal information
    # Then Individual should click on Individual market for plan shopping #TODO re-write this step
    # Then Individual should see a form to enter personal information
    # Then Individual sees previously saved address
    # Then Individual agrees to the privacy agreeement
    # Then Individual should see identity verification page and clicks on submit
    # Then Individual should see the dependents form
    # And Individual clicks on add member button
    # And Individual again clicks on add member button #TODO re-write this step
    # And I click on continue button on household info form
    # And I click the Got a New Dog QLE Kind link
    # And I fill in the QLE date with the first date of this month and click continue
    # And I click on continue button on group selection page
    # And I select three plans to compare
    # And I should not see any plan which premium is 0
    # And I select a plan on plan shopping page
    # And I click on purchase button on confirmation page
    # Then Individual logs out
    # Given Hbx Admin exists
    # When Hbx Admin logs on to the Hbx Portal
    # And Admin clicks Families tab
    # Then the Admin is navigated to the Families screen
    # And I click on the name of a person of family list
    # And I should see the individual home page
    # Then I should see "Got a New Dog" in qle carousel
