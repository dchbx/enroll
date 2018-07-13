Feature: Employee of a Sole Source Employer Shopping During Open Enrollment
  Background:
    Given there is a configured CCA benefit market, pricing models, and catalog
    And I have a CCA sole source employer health benefit package, in open enrollment
    And I am an employee eligible for shopping during open enrollment, who is linked
    And my eligible, linked employee is logged in

  Scenario: Group Selection During Open Enrollment
    When I visit the group selection page during open enrollment
    Then I should see a selectable list of family members for my group
    And I should see a selectable 'health' benefit option

  Scenario: Plan Browsing During Open Enrollment
    Given I have made a group selection during open enrollment
    When I visit the plan shopping page
    Then I should see my sole source plan
    And I should see the waive coverage button