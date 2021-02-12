Feature: Consumer verification process

  Scenario: Outstanding verification
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    * the user visits the Consumer portal during open enrollment
    * Individual creates HBX account
    * I should see a successful sign up message
    * the user sees Your Information page
    * the user registers as an individual
    * the individual clicks on the Continue button
    * user should see heading labeled personal information
    * Individual should click on Individual market for plan shopping
    * the individual sees form to enter personal information
    * Individual click continue button
    * Individual agrees to the privacy agreeement
    * the individual answers the questions of the Identity Verification page and clicks on submit
    * the individual is on the Help Paying for Coverage page
    * Individual does not apply for assistance and clicks continue
    * Individual should see the dependents form
    * the individual clicks on the Continue button of the Household Info page
    * I click on continue button on group selection page
    * I select a plan on plan shopping page
    * I click on purchase button on confirmation page
    * the individual clicks on the Continue button to go to the Individual home page
    * I should see Documents link
    * I click on verification link
    * I should see page for documents verification

  Scenario: Consumer with outstanding verification and uploaded documents
    Given a consumer exists
    And the consumer is logged in
    And consumer has outstanding verification and unverified enrollments
    When the consumer visits verification page
    Then consumer should see Verification Due date label
    And consumer should see Documents We Accept link
    And the consumer should see documents verification page

  Scenario: Consumer is fully_verified should see verification types
    Given a consumer exists
    And the consumer is logged in
    When the consumer is completely verified
    Then the consumer visits verification page
    And the consumer should see documents verification page
    Then verification types have to be visible

  Scenario: Consumer is from Curam and is fully verified and shows verification types as verified
    Given a consumer exists
    And the consumer is logged in
    When the consumer is completely verified from curam
    Then the consumer visits verification page
    And the consumer should see documents verification page
    Then verification types should display as verified state

  Scenario: Admin clicks on documents tab for Curam verified person
    Given a consumer exists
    And the consumer is logged in
    When the consumer is completely verified from curam
    Then the consumer visits verification page
    And consumer logs out
    When an HBX admin exists
    And clicks on the person in families tab
    Then verification types should display as external source
