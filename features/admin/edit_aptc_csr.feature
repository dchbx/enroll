Feature: Update APTC and CSR
    In order to update APTC and CSR
    User should have the role of an admin

    Background:
        Given User with tax household exists
        Given Hbx Admin exists
        When Hbx Admin logs on to the Hbx Portal
        When Hbx Admin click Families link
        And Hbx Admin clicks Actions button

    Scenario: Admin views the Edit APTC / CSR grid for an individual without an assistance recieving (with APTC) enrollment
        Then Hbx Admin should see an Edit APTC / CSR link

    Scenario: Admin tries to Apply APTC/CSR for Catastrophic plan
        And Hbx Admin clicks on the Update APTC CSR button
        Then Hbx Admin should see cat plan error message