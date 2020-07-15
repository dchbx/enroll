Feature: Admin can manage sep types like create, edit, update, delete and sort
  Background:
    Given an HBX admin exists
    Given the HBX admin is logged in
    Given the user is on the Main Page
    And the user will see the Manage Sep Types tab 
    When Admin clicks Manage Sep Types tab under admin dropdown
    

  Scenario: Navigate to Manage Sep Types screen
    When the Admin is navigated to the Manage Sep Types screen
    Then the Admin has the ability to use the following filters for documents provided: All, Individual, Shop and Congress
    And Hbx Admin logs out

  Scenario: Admin has ability to sort the sep types and save the positions to database
    When the Admin is navigated to the Manage Sep Types screen
    Then Admin will click on the Sorting Sep Types button
    #/html/body/div[3]/div[3]/a[1]

    # Then the Admin has the ability to use the following filters for documents provided: Fully Uploaded, Partially Uploaded, None Uploaded, All
    # Then the Admin is directed to that user's My DC Health Link page