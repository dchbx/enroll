Feature: EE plan purchase

  Scenario: when EE purchase plan for self & dependent
    Given a matched Employee exists with only employee role
    And employee has a valid "Married" qle
    Then Employee sign in to portal
    And employee has a dependent in child relationship with age less than 26
    When Employee click the "Married" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    When employee clicked continue on household info page
    Then employee should see all the family members names
    And employee clicked on shop for new plan
    Then employee should see both dependent and primary

  Scenario: when EE purchase plan only for primary
    Given a matched Employee exists with only employee role
    And employee has a valid "Married" qle
    Then Employee sign in to portal
    And employee has a dependent in child relationship with age less than 26
    When Employee click the "Married" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    When employee clicked continue on household info page
    Then employee should see all the family members names
    And employee cannot uncheck primary person
    When employee unchecks the dependent
    And employee clicked on shop for new plan
    Then employee should see primary person
    
  Scenario: EE having an ineligible family member & doing plan shop
    Given a matched Employee exists with only employee role
    And employee has a valid "Married" qle
    Then Employee sign in to portal
    And employee has a dependent in child relationship with age greater than 26
    When Employee click the "Married" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    When employee clicked continue on household info page
    Then employee should see all the family members names
    And employee should see the ineligible family member disabled and unchecked
    And employee should see the eligible family member enabled and checked
    And employee should also see the reason for ineligibility
    And employee should see the dental radio button
    And employee switched to dental benefits
    And employee should see the ineligible family member disabled and unchecked
    And employee should also see the reason for ineligibility
    And employee clicked on shop for new plan
    Then employee should see primary person

  Scenario: EE having an ineligible family member & doing plan shop
            - ER offers dental benefits for spouse in active plan year
            - ER not offers dental benefits for spouse in renewal plan year
            - ER is in renewal open enrollment period
    Given a matched Employee exists with active and renwal plan years
    And employee has a dependent in spouse relationship with age greater than 26
    And Employer not offers dental benefits for spouse in renewal plan year
    And employee has a valid "Married" qle
    Then Employee sign in to portal
    When Employee clicks "Shop for Plans" on my account page
    Then Employee should see the group selection page
    Then employee should see all the family members names
    And employee should not see the reason for ineligibility
    And employee should see the dental radio button
    Then employee switched to dental benefits
    And employee should see the ineligible family member disabled and unchecked
    And employee should see the eligible family member enabled and checked
    And employee should also see the reason for ineligibility
    When employee clicked on back to my account
    When Employee click the "Married" in qle carousel
    And I select a past qle date
    Then I should see confirmation and continue
    When employee coverage effective on date is under active plan year
    And employee clicked continue on household info page
    Then employee should see all the family members names
    And employee should not see the reason for ineligibility
    And employee should see the dental radio button
    When employee switched to dental benefits
    Then employee should not see the reason for ineligibility

  Scenario: EE plan shopping by clicking on 'make changes' button on enrollment
    Given a matched Employee exists with only employee role
    And employee has a dependent in child relationship with age greater than 26
    And employee has a dependent in spouse relationship with age greater than 26
    And employee also has a health enrollment with primary person covered
    Then Employee sign in to portal
    Then employee should see the enrollment with make changes button
    When employee clicked on make changes button
    Then employee should see the ineligible family member disabled and unchecked
    And employee should see the eligible family member enabled and checked
    And employee should also see the reason for ineligibility
    When employee clicked on shop for new plan
    Then employee should see primary and valid dependent

