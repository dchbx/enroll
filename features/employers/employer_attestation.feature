@ma_only
Feature: Employer Profile
  In order for initial employers to submit application
  Employer Staff should upload attestation document

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    And it has an employer ABC Widgets with no attestation submitted
    And ABC Widgets employer has a staff role
    And initial employer ABC Widgets has draft benefit application
    And staff role person logged in
    And ABC Widgets goes to the benefits tab I should see plan year information

  Scenario: Initial employer tries to submit application without uploading attestation
    When Employer clicks on publish plan year
    Then Employer Staff should not see force publish
    When Employer Staff clicks cancel button in Attestation warning dialog
    Then Employer Staff should redirect to plan year edit page

  #  Scenario: Initial employer tries to submit application after submitting the attestation
  #    When Employer clicks on publish plan year
  #    When Employer Staff clicks cancel button in Attestation warning dialog
  #    Then Employer uploads an attestation document
  #    And Employer should still see attestation upload button enabled
  #    When ABC Widgets goes to the benefits tab I should see plan year information
  #    When Employer clicks on publish plan year
  #    Then Plan Year should be moved to Enrolling

  Scenario: Admin approves the attestation
    Then Employer uploads an attestation document
    Then I click on log out link

    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    When Admin click all employers link
    When Admin clicks employer attestation filter
    Then Admin should see Employer with Submitted status
    When Admin clicks attestation action
    Then Admin should see attestation document
    When Admin clicks view attestation document
    Then Admin should see preview and attestation form
    When Admin clicks submit in employer attestation form
    Then Admin should see attestation updated message
    When Admin click all employers link
    When Admin clicks employer attestation filter
    Then Admin should see Employer with Approved status

    Then I click on log out link
    And staff role person logged in
    And ABC Widgets is logged in and on the home page
    And Employer Staff clicks documents tab
    Then Employer Staff should see attestation status Accepted
    And Employer should see attestation upload button disabled
    Then I click on log out link

  Scenario: Admin requests more information
    Then Employer uploads an attestation document
    Then I click on log out link

    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    When Admin click all employers link
    When Admin clicks employer attestation filter
    And Admin clicks submitted filter in employer attestation
    Then Admin should see Employer with Submitted status
    When Admin clicks attestation action
    Then Admin should see attestation document
    When Admin clicks view attestation document
    Then Admin should see preview and attestation form
    When Admin choose Request Additional Information
    And Admin enters the information needed
    And Admin clicks submit in employer attestation form
    Then Admin should see attestation updated message
    When Admin click all employers link
    When Admin clicks employer attestation filter
    And Admin clicks pending filter in employer attestation
    Then Admin should see Employer with Pending status

    Then I click on log out link
    And staff role person logged in
    And ABC Widgets is logged in and on the home page
    And Employer Staff clicks documents tab
    Then Employer Staff should see attestation status Info needed

  #  Scenario: Initial Employer with enrolled plan year and Admin denies Attestation
  #    Then Employer uploads an attestation document
  #    When ABC Widgets goes to the benefits tab I should see plan year information
  #    When Employer clicks on publish plan year
  #    Then Plan Year should be moved to Enrolling
  #
  #    Then I click on log out link
  #    Given a Hbx admin with read and write permissions exists
  #    When Hbx Admin logs on to the Hbx Portal
  #    When Admin click all employers link
  #    When Admin clicks employer attestation filter
  #    And Admin clicks submitted filter in employer attestation
  #    Then Admin should see Employer with Submitted status
  #    When Admin clicks attestation action
  #    Then Admin should see attestation document
  #    When Admin clicks view attestation document
  #    Then Admin should see preview and attestation form
  #    When Admin choose Reject
  #    And Admin enters the information needed
  #    And Admin clicks submit in employer attestation form
  #    Then Admin should see attestation updated message
  #    When Admin click all employers link
  #    When Admin clicks employer attestation filter
  #    And Admin clicks denied filter in employer attestation
  #    Then Admin should see Employer with Denied status
  #
  #    Then I click on log out link
  #    And staff role person logged in
  #    And ABC Widgets is logged in and on the home page
  #    And Employer Staff clicks documents tab
  #    Then Employer Staff should see attestation status Rejected
  #    When ABC Widgets goes to the benefits tab I should see plan year information
  #    # Then Plan Year should be moved to Canceled
  #    # When Employer staff clicks employees tab
  #    # Then Employer staff should employees coverage status as canceled

  Scenario: Initial Employer with active plan year and Admin denies Attestation
    Then Employer uploads an attestation document
    Then I click on log out link
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    When Admin click all employers link
    When Admin clicks employer attestation filter
    And Admin clicks submitted filter in employer attestation
    Then Admin should see Employer with Submitted status
    When Admin clicks attestation action
    Then Admin should see attestation document
    When Admin clicks view attestation document
    Then Admin should see preview and attestation form
    When Admin choose Reject
    And Admin enters the information needed
    And Admin clicks submit in employer attestation form
    Then Admin should see attestation updated message
    When Admin click all employers link
    When Admin clicks employer attestation filter
    And Admin clicks denied filter in employer attestation
    Then Admin should see Employer with Denied status

    Then I click on log out link
    And staff role person logged in
    And ABC Widgets is logged in and on the home page
    And Employer Staff clicks documents tab
    Then Employer Staff should see attestation status Rejected
    When ABC Widgets goes to the benefits tab I should see plan year information
    Then I click on log out link

  Scenario: Employer Deletes submitted documents
    Then Employer uploads an attestation document
    And Employer clicks delete in actions
    Then Employer should not see submitted document
    Then I click on log out link

  Scenario: Employer should not be allowed to delete a document which is not in 'submitted' state. i.e, accepted, rejected or info needed
    Then Employer uploads an attestation document
    Then I click on log out link
    Given a Hbx admin with read and write permissions exists
    When Hbx Admin logs on to the Hbx Portal
    When Admin click all employers link
    When Admin clicks employer attestation filter
    And Admin clicks submitted filter in employer attestation
    Then Admin should see Employer with Submitted status
    When Admin clicks attestation action
    Then Admin should see attestation document
    When Admin clicks view attestation document
    Then Admin should see preview and attestation form
    When Admin clicks submit in employer attestation form
    Then Admin should see attestation updated message
    Then I click on log out link
    And staff role person logged in
    And ABC Widgets is logged in and on the home page
    Then Employer Staff clicks documents tab
    And Employer should see disabled delete button in actions