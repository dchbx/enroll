Feature: Update DOB and SSN
    In order to update DOB and SSN
    User should have the role of an admin
    
    Scenario: Admin enters invalid DOB or SSN
        Given Hbx Admin exists
            When Hbx Admin logs on to the Hbx Portal
            When Hbx Admin clicks on Families link
            Then Hbx Admin should see the list of primary applicants and an Action button
            When Hbx Admin clicks on the Action button
            Then Hbx Admin should see an edit DOB/SSN link
            When Hbx Admin clicks on edit DOB/SSN link
            When Hbx Admin enters an invalid SSN and clicks on update
            Then Hbx Admin should see the edit form being rendered again with a validation error message
            And Hbx Admin logs out


    Scenario: Admin enters valid DOB and SSN
        Given Hbx Admin exists
            When Hbx Admin logs on to the Hbx Portal
            When Hbx Admin clicks on Families link
            Then Hbx Admin should see the list of primary applicants and an Action button
            When Hbx Admin clicks on the Action button
            Then Hbx Admin should see an edit DOB/SSN link
            When Hbx Admin clicks on edit DOB/SSN link
            When Hbx Admin enters a valid DOB and SSN and clicks on update
            Then Hbx Admin should see the update partial rendered with update sucessful message
            And Hbx Admin logs out