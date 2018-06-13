Feature: Reset password of user
 In order to reset password of the user
 User should have the role of an admin

  Scenario: Admin can reset password of the user if has permission
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And I select the all security question and give the answer
    When I have submit the security questions
    Then there are 1 preloaded unlocked user accounts
    When Hbx Admin clicks on the User Accounts tab
    Then Hbx Admin should see the list of primary applicants and Action buttons
    When Hbx Admin clicks on the Action button of primary applicant
    Then Hbx Admin should see Reset Password link in action drop down
    When Hbx Admin clicks on Reset Password link in action drop down
    And Hbx admin confirms password send
    Then the reset password email should be sent to the user


  Scenario: Admin can add user email address to reset password if email does not exist
    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And I select the all security question and give the answer
    When I have submit the security questions
    Then there are 1 preloaded user accounts without email
    When Hbx Admin clicks on the User Accounts tab
    Then Hbx Admin should see the list of primary applicants and Action buttons
    When Hbx Admin clicks on the Action button of primary applicant
    Then Hbx Admin should see Reset Password link in action drop down
    When Hbx Admin clicks on Reset Password link in action drop down
    Then Hbx Admin can see the enter email for reset password modal
    And Hbx Admin fill the admin@dc.gov email address for that user
    When Hbx Admin submit the reset password modal form
    Then an error Email is already taken should be raised
    And Hbx Admin fill the testuser@email.com email address for that user
    When Hbx Admin submit the reset password modal form
    Then Hbx Admin clicks on the User Accounts tab
    And the primary applicant email should be testuser@email.com
    And the reset password email should be sent to the user
