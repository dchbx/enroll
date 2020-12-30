Feature: EE with consumer role plan purchase

  # TODO: revisit code for background scenarios
  Background: Setup permissions, HBX Admin, users, and organizations and employer profiles
    Given a consumer role person with family
    Given an employer with initial application
    Given all products with issuer profile
    Then  an application provides health and dental packages
    Then there are sponsored benefit offerings for spouse and child

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

  Scenario: User should not see IVL "Make Changes" button for SHOP enrollments
    Given a matched Employee exists with consumer role
    And user has a dependent in child relationship with age less than 26
    And user has a dependent in spouse relationship with age greater than 26
    And user did not apply coverage for child as ivl
    And employee also has a health enrollment with primary covered under first employer
    Then Employee sign in to portal
    And employee shouldnt see make changes button in individual market
    And employee should see make changes button in shop market

