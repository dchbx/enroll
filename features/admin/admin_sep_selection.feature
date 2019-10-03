Feature: Purchasing through SEP
  Scenario: Admin purchases the an insured user through sep
    Given Individual has not signed up as an HBX user
    And qualifying life event kind Had a baby present for individual market
    And individual qualifying life event kind Had a baby has start_on and end_on date within current date range
    And all qualifying life event kinds are visible to customer
    When Individual visits the Insured portal during open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
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
    Then Individual logs out
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And I click on the name of a person of family list
    And I should see the individual home page
    When I click the "Had a baby" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue

  Scenario: Admin attempts to purchase the an insured user through sep, but sep not visible
    Given Individual has not signed up as an HBX user
    And qualifying life event kind Had a baby present for individual market
    And all qualifying life event kinds are not visible to customer
    When Individual visits the Insured portal during open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
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
    Then Individual logs out
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And I click on the name of a person of family list
    And I should see the individual home page
    Then I should not see "Had a baby" in qle carousel

  Scenario: User can enroll with the accepted response for QLE Kind with custom qle_questions
    Given Individual has not signed up as an HBX user
    And qualifying life event kind Had a baby present for individual market
    And qualifying life event kind Had a baby has custom qle question and accepted response present
    And individual qualifying life event kind Had a baby has start_on and end_on date within current date range
    And all qualifying life event kinds are visible to customer
    When Individual visits the Insured portal during open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
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
    Then Individual logs out
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And I click on the name of a person of family list
    And I should see the individual home page
    When I click the "Had a baby" in qle carousel
    And I see the custom qle questions for Had a baby qualifying life event kind
    And I fill out the accepted response for Had a baby qualifying life event kind
    And I see the new insured group selection page and a message confirming that I can enroll

  Scenario: User cannot enroll with the declined response for QLE Kind with custom qle_questions
    Given Individual has not signed up as an HBX user
    And qualifying life event kind Had a baby present for individual market
    And qualifying life event kind Had a baby has custom qle question and declined response present
    And all qualifying life event kinds are visible to customer
    And individual qualifying life event kind Had a baby has start_on and end_on date within current date range
    When Individual visits the Insured portal during open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
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
    Then Individual logs out
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And I click on the name of a person of family list
    And I should see the individual home page
    When I click the "Had a baby" in qle carousel
    And I see the custom qle questions for Had a baby qualifying life event kind
    And I fill out the declined response for Had a baby qualifying life event kind
    And I see the home page and a message informing me that I'm unable to enroll

  Scenario: User must fill out second question with accepted response if redirected from two_question_2 in order to enroll
    Given Individual has not signed up as an HBX user
    And qualifying life event kind Had a baby present for individual market
    And qualifying life event kind Had a baby has two custom qle questions with a to_question_2 response present
    And individual qualifying life event kind Had a baby has start_on and end_on date within current date range
    And all qualifying life event kinds are visible to customer
    When Individual visits the Insured portal during open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
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
    Then Individual logs out
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And I click on the name of a person of family list
    And I should see the individual home page
    When I click the "Had a baby" in qle carousel
    And I see the first custom qle question for Had a baby qualifying life event kind
    And I fill out the to_question_2 response for Had a baby qualifying life event kind
    And I see the second custom custom qle question for Had a baby qualifying life event kind
    And I fill out the accepted response for Had a baby qualifying life event kind
    And I see the new insured group selection page and a message confirming that I can enroll

  Scenario: User is redirected to call center if they choose response for call_center
    Given Individual has not signed up as an HBX user
    And qualifying life event kind Had a baby present for individual market
    And qualifying life event kind Had a baby has custom qle question and call_center response present
    And individual qualifying life event kind Had a baby has start_on and end_on date within current date range
    And all qualifying life event kinds are visible to customer
    When Individual visits the Insured portal during open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
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
    Then Individual logs out
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And I click on the name of a person of family list
    And I should see the individual home page
    When I click the "Had a baby" in qle carousel
    And I see the custom qle questions for Had a baby qualifying life event kind
    And I fill out the call_center response for Had a baby qualifying life event kind
    And I see the call center page and a phone number to call so I can be approved for enrollment

  Scenario: User cannot see QLE Kind if current date not between or equal to start on and end on of event
    Given Individual has not signed up as an HBX user
    And qualifying life event kind Had a baby present for individual market
    And individual qualifying life event kind Had a baby has start_on and end_on date not within current date range
    And qualifying life event kind Natural Disaster present for individual market
    And individual qualifying life event kind Natural Disaster has start_on and end_on date within current date range
    And all qualifying life event kinds are visible to customer
    When Individual visits the Insured portal during open enrollment
    Then Individual creates HBX account
    Then I should see a successful sign up message
    And user should see your information page
    When user goes to register as an individual
    When user clicks on continue button
    Then user should see heading labeled personal information
    Then Individual should click on Individual market for plan shopping #TODO re-write this step
    Then Individual should see a form to enter personal information
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
    Then Individual logs out
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Admin clicks Families tab
    Then the Admin is navigated to the Families screen
    And I click on the name of a person of family list
    And I should see the individual home page
    Then I should not see a link to enroll with the Had a baby qualifying life event kind
    And I should see a link to enroll with the Natural Disaster qualifying life event kind
