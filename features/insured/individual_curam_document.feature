Feature: Customers go to Curam to view notices and verifications

  Scenario: Consumer can see the Navigation Button
    Given a consumer exists
    And the consumer is logged in
    When the consumer visits verification page
    And the user navigates to the DOCUMENTS tab
    Then a button will be visible to the user labeled GO TO MEDICAID

  Scenario: Consumer can see the text on left to the Navigation Button
    Given a consumer exists
    And the consumer is logged in
    When the consumer visits verification page
    And the user navigates to the DOCUMENTS tab
    When GO TO MEDICAID button is visible to the user
    Then there will be text to the left of the GO TO MEDICAID button

  Scenario: On click Consumer navigates to Curam/Drupal login
    Given a consumer exists
    And the consumer is logged in
    When the consumer visits verification page
    And the user navigates to the DOCUMENTS tab
    When the user clicks on the GO TO MEDICAID button
    Then EA sets a flag in IAM to direct the consumer to the curam/ drupal login

  Scenario: HbxAdmin can see the Navigation Button
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab
    And selects a Person account and navigates to Verification page
    And the user navigates to the DOCUMENTS tab
    Then a button will be visible to the user labeled GO TO MEDICAID

  Scenario: HbxAdmin can see the text on left to the Navigation Button
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab
    And selects a Person account and navigates to Verification page
    When GO TO MEDICAID button is visible to the user
    Then there will be text to the left of the GO TO MEDICAID button

  Scenario: On click HbxAdmin navigates to Curam/Drupal login
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab
    And selects a Person account and navigates to Verification page
    When the user clicks on the GO TO MEDICAID button
    Then EA sets a flag in IAM to direct the consumer to the curam/ drupal login

  Scenario: Broker can see the Navigation Button
    Given that a broker exists
    And the broker is signed in
    When the broker visits verification page
    And the user navigates to the DOCUMENTS tab
    Then a button will be visible to the user labeled GO TO MEDICAID

  Scenario: Broker can see the Navigation Button
    Given that a broker exists
    And the broker is signed in
    When the broker visits verification page
    And the user navigates to the DOCUMENTS tab
    When GO TO MEDICAID button is visible to the user
    Then there will be text to the left of the GO TO MEDICAID button

  Scenario: Broker can see the Navigation Button
    Given that a broker exists
    And the broker is signed in
    When the broker visits verification page
    And the user navigates to the DOCUMENTS tab
    When the user clicks on the GO TO MEDICAID button
    Then EA sets a flag in IAM to direct the consumer to the curam/ drupal login

  Scenario: Consumer can see the Navigation Button
    Given a consumer exists
    And the consumer is logged in
    When the user visits messages page
    Then there will be messages text to the left of the GO TO MEDICAID button
    When the user clicks on the GO TO MEDICAID button
    Then EA sets a flag in IAM to direct the consumer to the curam/ drupal login

  Scenario: HbxAdmin can see the Navigation Button
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    And the Hbx Admin clicks on the Families tab
    And selects a Person account and navigates to Messages page
    Then there will be messages text to the left of the GO TO MEDICAID button
    When the user clicks on the GO TO MEDICAID button
    Then EA sets a flag in IAM to direct the consumer to the curam/ drupal login

  Scenario: Broker can see the Navigation Button
    Given that a broker exists
    And the broker is signed in
    When the user visits messages page
    Then there will be messages text to the left of the GO TO MEDICAID button
    When the user clicks on the GO TO MEDICAID button
    Then EA sets a flag in IAM to direct the consumer to the curam/ drupal login