Feature: Employer creates a profile
  And views a flash message if there are no products
  When creating a plan year

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    When staff role person logged in

  Scenario:
   Given employer ABC Widgets visits benefits page
   And Employer doesn't have benefit applications
   When Employer clicks on Add PlanYear button
   Then Employer should see shell plan year page
   And Employer clicks on all valid information
   When Employer clicks on Continue Button 
   Then Employer should see late rates flash message
   And Employer should have Draft Shell plan year