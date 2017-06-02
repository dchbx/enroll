Feature: Enable or Disable Person record
    In order to enable/disable person record
    User should have the role of an admin
    
    Scenario: Admin enters into Families index
        Given Hbx Admin exists
            When Hbx Admin logs on to the Hbx Portal
            Then Hbx Admin sees Families index
            
            When Hbx Admin clicks on the Families tab
            Then Hbx Admin should see an Actions link
           
            When Hbx Admin clicks on the Actions button
            Then Hbx Admin should see an Enable / Disable link
            
            When Hbx Admin clicks on the Enable / Disable link
            Then Hbx Admin should see the person record disabled
            


