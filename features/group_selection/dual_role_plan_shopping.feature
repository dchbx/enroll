Feature: EE with consumer role plan purchase

  Scenario: when user purchase plan for self & having ineligible family member
    Given a matched Employee exists with consumer role
    And first ER not offers dental benefits to spouse
    Then Employee sign in to portal
    And user has a dependent in spouse relationship with age less than 26
    And user has a dependent in child relationship with age less than 26
    And user did not apply coverage for child as ivl
    When employee clicked on shop for plans
    Then employee should see all the family members names
    And employee should see the dental radio button
    And employee should not see the reason for ineligibility
    And employee switched to dental benefits
    And employee should see the ineligible family member disabled and unchecked
    And employee should see the eligible family member enabled and checked
    And employee should also see the reason for ineligibility
    When employee switched for individual benefits
    Then employee should see the dental radio button
    Then user should see the ivl error message
    When employee switched for employer-sponsored benefits
    Then employee should not see the reason for ineligibility
    When employee unchecks the dependent
    And employee clicked on continue for plan shopping
    Then employee should see primary and valid dependent

  Scenario: user plan shopping by clicking on 'make changes' button of IVL health enrollment
    Given a matched Employee exists with consumer role
    And first ER not offers dental benefits to spouse
    And user has a dependent in spouse relationship with age less than 26
    And user has a dependent in child relationship with age less than 26
    And user did not apply coverage for child as ivl
    And user also has a health enrollment with primary person covered
    Then Employee sign in to portal
    Then employee should see the enrollment with make changes button
    When employee clicked on make changes button
    Then user should see the ivl error message

  Scenario: user plan shopping by clicking on 'make changes' button of SHOP dental enrollment
            -- ER not offers shop dental benefits for child under 26
    Given a matched Employee exists with consumer role
    And user has a dependent in child relationship with age less than 26
    And user has a dependent in spouse relationship with age greater than 26
    And user did not apply coverage for child as ivl
    And employee also has a dental enrollment with primary covered under first employer
    Then Employee sign in to portal
    Then employee should see the enrollment with make changes button
    When employee clicked on make changes button
    Then employee should see the ineligible family member disabled and unchecked
    And employee should see the eligible family member enabled and checked
    Then user should not see the ivl error message
    And employee should also see the reason for ineligibility
    And employee clicked on shop for new plan
    Then employee should see primary and valid dependent

