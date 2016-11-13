Feature: Update APTC and CSR
    In order to update APTC and CSR
    User should have the role of an admin
    
    Scenario: Admin views the Edit APTC / CSR grid for an individual without an assistance recieving (with APTC) enrollment
        Given Hbx Admin exists
            When Hbx Admin logs on to the Hbx Portal
            Then Hbx Admin sees Families link
            When Hbx Admin clicks on Families link
            Then Hbx Admin should see the list of primary applicants and an Action button
            When Hbx Admin clicks on the Action button
            Then Hbx Admin should see an Edit APTC / CSR link

