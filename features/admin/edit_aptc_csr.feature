Feature: Update APTC and CSR
    In order to update APTC and CSR
    User should have the role of an admin

    Scenario: Admin views the Edit APTC / CSR grid for an individual without an assistance recieving (with APTC) enrollment
        Given Hbx Admin exists
        When Hbx Admin logs on to the Hbx Portal
        When Hbx Admin click Families link
        Then Hbx Admin should see the list of primary applicants and an Action button
        When Hbx Admin clicks Action button
        Then Hbx Admin should see an Edit APTC / CSR link

    Scenario: Admin SHOULD NOT SEE the Edit APTC / CSR grid for an individual with catastrophic plan
        Given Hbx Admin exists
        When Hbx Admin logs on to the Hbx Portal
        When Hbx Admin click Families link
        Then Hbx Admin should see the list of primary applicants and an Action button
        When Hbx Admin clicks Action button
        Then Hbx Admin should not see an Edit APTC / CSR link