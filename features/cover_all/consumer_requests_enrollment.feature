@individual_enabled
Feature: Consumer requests enrollment in CoverAll
  As a person who is aware in advance that he is not qualified for QHP through the
  exchange, and has not initialized an application through EA, he can request to
  be enrolled in CoverAll. The HBX admin can then enter their information and
  process their application through the families index page.

  Scenario: When we login as Hbx admin with read and write permissions then on family tab we should see link New DC Resident Application
    Given a Hbx admin with super admin access exists
    When Hbx Admin logs on to the Hbx Portal
    Then Hbx Admin sees Families link
    When Hbx Admin clicks on Families link
    Then Hbx Admin should see an New DC Resident Application link
    When Hbx Admin clicks on New DC Resident Application link
    Then Hbx Admin should see New DC Resident Personal Information page
    When HBX Admin goes to register an user as individual
    Then HBX Admin clicks on continue button
    Then user should see heading labeled personal information
    Then HBX Admin should see a form to enter personal information
    Then Hbx Admin should see text Household Info
    Then Hbx Admin should see text Special Enrollment Period
    When Hbx Admin click the "Married" in qle carousel
    And Hbx Admin select a past qle date
    Then Employee should see confirmation and clicks continue
    When I click on continue button on group selection page during a sep
    Then HBX Admin should see the list of plans
    When HBX Admin selects a plan from shopping plan page
    Then HBX Admin should see the summary page of plan selection
    When HBX Admin clicks on Confirm button on the summary page of plan selection
    Then HBX Admin should see the enrollment receipt page
    When HBX Admin clicks go to my account button
    Then HBX Admin should see the home page with text coverage selected

   Scenario: When we login as Hbx admin with only read permissions then on family tab we should not see link New DC Resident Application
    Given a Hbx admin with read only permissions exists
    When Hbx Admin logs on to the Hbx Portal
    Then Hbx Admin sees Families link
    When Hbx Admin clicks on Families link
    Then Hbx Admin should not see an New DC Resident Application link
