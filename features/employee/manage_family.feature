Feature: Employees can update their password or security questions

  An employee should be able to update their own password or security question responses

  Scenario: An employee can update their password with the correct original password
    Given Renewing Employer for Soren White exists with active and renewing plan year
      And Soren White already matched and logged into employee portal
      Then Employee Soren White should click Manage Family
      Then Employee Soren White should click the Personal Tab
      Then Employee Soren White should click Change my Password
      Then they can submit a new password
      And they should see a successful password message

  Scenario: An employee cannot update their password without the correct original password
    Given Renewing Employer for Soren White exists with active and renewing plan year
      And Soren White already matched and logged into employee portal
      Then Employee Soren White should click Manage Family
      Then Employee Soren White should click the Personal Tab
      Then Employee Soren White should click Change my Password
      Then they attempt to submit a new password
      And they should see a password error message

  Scenario: An employee can update their security question responses
    Given Renewing Employer for Soren White exists with active and renewing plan year
      And Soren White already matched and logged into employee portal
      Then Employee Soren White should click Manage Family
      Then Employee Soren White should click the Personal Tab
      Then Employee Soren White should click Update my security challenge responses
      When I select the all security question and give the answer
      When I have submit the security questions
      Then I should see a security response success message
