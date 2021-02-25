Feature: Insured Plan Shopping on Individual Assisted market

  Background: Individual market setup
    Given an Individual has not signed up as an HBX user
    And the FAA feature configuration is enabled

  Scenario: Validation of new APTC tool UI changes
    Given the user visits the Consumer portal during open enrollment
    When the user creates a Consumer role account
    And the user sees Your Information page
    And the user registers as an individual
    And the individual clicks on the Continue button
    And the individual sees form to enter personal information
    And the individual clicks on the Continue button
    And the individual agrees to the privacy agreeement
    And the individual answers the questions of the Identity Verification page and clicks on submit
    When the individual is on the Help Paying for Coverage page
    And the individual does not apply for assistance and clicks continue
    And the individual clicks on the Continue button of the Household Info page
    # And the individual enters a SEP
    And taxhousehold info is prepared for aptc user
    When the individual clicks on the Continue button of the Group Selection page
    And the individual is in the Plan Selection page
    Then the individual sees the new APTC tool UI changes
    When the individual sets APTC amount
    And the individual selects a silver plan on Plan Shopping page
    Then the individual should see the elected APTC amount and click on the Confirm button of the Thank You page
    And the individual should see the APTC amount on the Receipt page
    And the individual clicks on the Continue button to go to the Individual home page
    Then the individual should see the elected aptc amount applied to enrollment in the Individual home page
    Then the individual logs out

  Scenario: Validation of the dailog box when selecting a non silver plan with eligiblity
    Given the user visits the Consumer portal during open enrollment
    When the user creates a Consumer role account
    And the user sees Your Information page
    And the user registers as an individual
    And the individual clicks on the Continue button 
    And the individual sees form to enter personal information
    And the individual clicks on the Continue button
    And the individual agrees to the privacy agreeement
    And the individual answers the questions of the Identity Verification page and clicks on submit
    And the individual clicks on the Continue button of the Household Info page
    When taxhousehold info is prepared for aptc user with selected eligibility
    And the individual does not apply for assistance and clicks continue
    And the individual clicks on the Continue button of the Household Info page
    # And the individual enters a SEP
    And the individual clicks on the Continue button of the Group Selection page
    When the individual sets APTC amount
    And the individual selects a non silver plan on Plan Shopping page
    Then the individual should see the modal pop up for eligibility