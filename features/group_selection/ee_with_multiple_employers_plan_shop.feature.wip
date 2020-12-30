@wip @bug
Feature: EE with multiple employers plan purchase

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given Qualifying life events are present
    And there is an employer ABC Widgets
    And there is an employer DEF Sales
    And initial employer ABC Widgets has active benefit application
    And initial employer DEF Sales has active benefit application
    Then person has multiple employee roles with benefits from employers ABC Widgets and DEF Sales

  Scenario: when EE purchase plan for self & having ineligible family member -
    ER1 ABC Widgets - Health & dental benefits - not offers dental benefits to spouse
    ER2 DEF Sales - Only Health benefits - not offers to spouse
    Employee - John
    # follow below step to replicate issue
    Given there exists Patrick Doe employee for employer ABC Widgets and DEF Sales
    And employee Patrick Doe already matched with employer ABC Widgets and DEF Sales and logged into employee portal
    And employee Patrick Doe with a dependent has spouse relationship with age less than 26
    And this employer ABC Widgets not offering dental benefits to Spouse
    And this employer DEF Sales not offering health benefits to Spouse
    When Employee click the "Married" in qle carousel
    And Employee select a past qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    And Patrick Doe should see all the family members names
    And Patrick Doe should see the dental radio button
    And employee should not see the reason for ineligibility
    And Patrick Doe switched to dental benefits
    And Patrick Doe should see the ineligible family member disabled and unchecked
    And Patrick Doe should see the eligible family member enabled and checked
    And Patrick Doe should also see the reason for ineligibility
    When employee switched to second employer
    And Patrick Doe should see the dental radio button
    And employee should see the ineligible family member disabled and unchecked
    And employee should see the eligible family member enabled and checked
    And Patrick Doe should also see the reason for ineligibility
    When employee switched to first employer
    Then employee should see the dental radio button
    And employee should not see the reason for ineligibility
    When employee unchecks the dependent
    And employee clicked on shop for new plan
    Then employee should see primary person

  # TODO fix scenario after bug is fixed.

  Scenario: EE plan shopping by clicking on 'make changes' button of health enrollment in the above scenario
    Given a matched Employee exists with multiple employee roles
    And employee has a dependent in child relationship with age greater than 26
    And employee has a dependent in spouse relationship with age greater than 26
    And employee also has a health enrollment with primary covered under first employer
    Then Employee sign in to portal
    Then employee should see the enrollment with make changes button
    When employee clicked on make changes button
    Then employee should not see the reason for ineligibility
    When employee clicked on shop for new plan
    Then employee should see primary and valid dependent

    # TODO fix scenario after bug is fixed.
  
  Scenario: EE plan shopping by clicking on 'make changes' button of dental enrollment in the above scenario
    Given a matched Employee exists with multiple employee roles
    And employee has a dependent in child relationship with age greater than 26
    And employee has a dependent in spouse relationship with age greater than 26
    And employee also has a dental enrollment with primary covered under first employer
    Then Employee sign in to portal
    Then employee should see the enrollment with make changes button
    When employee clicked on make changes button
    Then employee should see the ineligible family member disabled and unchecked
    And employee should see the eligible family member enabled and checked
    And employee should also see the reason for ineligibility
    When employee clicked on shop for new plan
    Then employee should see primary and valid dependent
