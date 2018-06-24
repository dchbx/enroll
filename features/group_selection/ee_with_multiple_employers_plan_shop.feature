Feature: EE with multiple employers plan purchase

  Scenario: when EE purchase plan for self & having ineligible family member - 
            ER1 - Health & dental benefits - not offers dental benefits to spouse
            ER2 - Only Health benefits - not offers to spouse
    Given a matched Employee exists with multiple employee roles
    And employee has a valid "Married" qle
    And second ER not offers health benefits to spouse
    And first ER not offers dental benefits to spouse
    Then Employee sign in to portal
    And employee has a dependent in spouse relationship with age less than 26
    When Employee click the "Married" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    When employee clicked continue on household info page
    Then employee should see all the family members names
    And employee should see the dental radio button
    And employee should not see the reason for ineligibility
    And employee switched to dental benefits
    And employee should see the ineligible family member disabled and unchecked
    And employee should see the eligible family member enabled and checked
    And employee should also see the reason for ineligibility
    When employee switched to second employer
    Then employee should not see the dental radio button
    And employee should see the ineligible family member disabled and unchecked
    And employee should see the eligible family member enabled and checked
    And employee should also see the reason for ineligibility
    When employee switched to first employer
    Then employee should see the dental radio button
    And employee should not see the reason for ineligibility
    When employee unchecks the dependent
    And employee clicked on shop for new plan
    Then employee should see primary person

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

