Feature: Insured VLP Verification for Individual market

  Background:
    Given Individual has not signed up as an HBX user
    When the user visits the Consumer portal during open enrollment
    Then Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And the user sees Your Information page
    When the user registers as an individual
    When the individual clicks on the Continue button
    Then Individual logs out

  @flaky
  Scenario: Individual should be able to succesfully add a valid alphanumeric i94 number for I-94 (Arrival/Departure Record).
    Given Individual resumes enrollment
    And Individual click on Sign In
    And I signed in
    Then Individual should see heading labeled personal information
    Then Individual should see a form to enter personal information
    And Individual selects eligible immigration status
    Then selects the i94 document and fills required details correctly
    Then Individual should see the i94 text
    And Individual selects applying for coverage
    When Individual clicks on continue
    Then Individual does go to Authorization and Consent page
    Then Individual logs out

  Scenario: Individual should not be able to succesfully add an invalid alphanumeric i94 number for I-94 (Arrival/Departure Record).
    Given Individual resumes enrollment
    And Individual click on Sign In
    And I signed in
    Then Individual should see heading labeled personal information
    Then the individual sees form to enter personal information
    And Individual selects eligible immigration status
    Then selects the i94 document and fills required details incorrectly
    Then Individual should see the i94 text
    And Individual selects applying for coverage
    When Individual clicks on continue
    Then Individual doesnot go to Authorization and Consent page
    Then Individual logs out

  @flaky
  Scenario: Individual should be able to succesfully add a valid alphanumeric i94 number for I-94 (Arrival/Departure Record) in Unexpired Foreign Passport.
    Given Individual resumes enrollment
    And Individual click on Sign In
    And I signed in
    Then Individual should see heading labeled personal information
    Then Individual should see a form to enter personal information
    And Individual selects eligible immigration status
    Then selects i94 unexpired foreign passport document and fills required details correctly
    Then Individual should see the i94 text
    And Individual selects applying for coverage
    When Individual clicks on continue
    Then Individual does go to Authorization and Consent page
    Then Individual logs out

  Scenario: Individual should not be able to succesfully add an invalid alphanumeric i94 number for I-94 (Arrival/Departure Record) in Unexpired Foreign Passport.
    Given Individual resumes enrollment
    And Individual click on Sign In
    And I signed in
    Then Individual should see heading labeled personal information
    Then the individual sees form to enter personal information
    And Individual selects eligible immigration status
    Then selects i94 unexpired foreign passport document and fills required details incorrectly
    Then Individual should see the i94 text
    And Individual selects applying for coverage
    When Individual clicks on continue
    Then Individual doesnot go to Authorization and Consent page
    Then Individual logs out

  @flaky
  Scenario: Individual should be able to succesfully add a valid alphanumeric i94 number for Other With I-94 Number.
    Given Individual resumes enrollment
    And Individual click on Sign In
    And I signed in
    Then Individual should see heading labeled personal information
    Then Individual should see a form to enter personal information
    And Individual selects eligible immigration status
    Then selects Other With I-94 Number document and fills required details correctly
    Then Individual should see the i94 text
    And Individual selects applying for coverage
    When Individual clicks on continue
    Then Individual does go to Authorization and Consent page
    Then Individual logs out

  Scenario: Individual should not be able to succesfully add an invalid alphanumeric i94 number for Other With I-94 Number.
    Given Individual resumes enrollment
    And Individual click on Sign In
    And I signed in
    Then Individual should see heading labeled personal information
    Then the individual sees form to enter personal information
    And Individual selects eligible immigration status
    Then selects Other With I-94 Number document and fills required details incorrectly
    Then Individual should see the i94 text
    And Individual selects applying for coverage
    When Individual clicks on continue
    Then Individual doesnot go to Authorization and Consent page
    Then Individual logs out
