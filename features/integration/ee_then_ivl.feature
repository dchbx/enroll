@individual_enabled
Feature: Insured Enrolls as Employee then as Consumer and then does IVL purchase
  Scenario: New insured user purchases on individual market
     Given Individual has not signed up as an HBX user
     Given a plan year, with premium tables, exists
     Given Company Tronics is created with benefits
     #Given Tronics clicks on the Employees tab
     #Given Tronics clicks on the add employee button
     #Given Tronics creates Fred as a roster employee
     Given Tronics clicks on the Employees tab
     Given Tronics clicks on the add employee button
     Given Tronics creates Megan as a roster employee
     Given Company Tronics logs out

     When Megan visits the Employee portal
     When Megan creates a new account
     When Megan enters person search data

     When Megan selects Company match for Tronics
     When Megan clicks continue
     Then Megan sees the Household Info: Family Members page
     When Megan logs out

     When Megan visits the Consumer Portal
     When Megan signs in
     Then Megan sees the Your Information page
     When Megan continues
     When Megan enters person search data

     When Megan continues
     When Megan enters demographic information
     When Megan continues again
     Then Megan sees the Verify Identity page
     When Megan logs out

     When Megan visits the Consumer Portal
     When Megan signs in

     Then Individual should see identity verification page and clicks on submit
     Then Individual should see the dependents form
     And Individual clicks on add member button
     And Individual again clicks on add member button
     And I click on continue button on household info form
     And I click on continue button on group selection page
     And I select a plan on plan shopping page
     #And I click on purchase button on confirmation page
     And Megan clicks on the purchase button on the confirmation page
     And I click on continue button to go to the individual home page
     And I should see the individual home page

     When I click the "Married" in qle carousel
       And I select a future qle date
       Then I should see not qualify message
       When I click the "Married" in qle carousel
       And I select a past qle date
       Then I should see confirmation and continue
       When I click on continue button on household info form
       And I click on "shop for new plan" button on household info page
       And I select a plan on plan shopping page
       And Megan clicks on the purchase button on the confirmation page
       When I click on continue on qle confirmation page
       And I should see the individual home page
     Then Megan logs out

     When Megan visits the Employee portal
     When Megan signs in
     Then Megan sees the Household Info: Family Members page
     Then Megan logs out
