Feature: IVL plan purchase

  Scenario: when Resident purchase plan for self & dependent
    Given a Resident exists
    And the Resident is logged in
    And Resident has a dependent in child relationship with age less than 26
    When Resident has QLE and goes to home page
    And Resident clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When Resident clicked continue on household info page
    Then Resident should see all the family members names
    And Resident clicked on shop for new plan
    Then Resident should see both dependent and primary

  Scenario: when IVL purchase plan only for dependent
    Given a Resident exists
    And the Resident is logged in
    And Resident has a dependent in child relationship with age less than 26
    When Resident has QLE and goes to home page
    And Resident clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When Resident clicked continue on household info page
    Then Resident should see all the family members names
    When Resident unchecks the primary person
    And Resident clicked on shop for new plan
    Then Resident should only see the dependent name

  Scenario: IVL having an ineligible family member & doing plan shop
    Given a Resident exists
    And the Resident is logged in
    And Resident has a dependent in child relationship with age greater than 26
    When Resident has QLE and goes to home page
    And Resident clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When Resident clicked continue on household info page
    Then Resident should see all the family members names
    And Resident should see the ineligible family member disabled and unchecked
    And Resident should see the eligible family member enabled and checked
    And Resident should also see the reason for ineligibility
    And Resident should see the dental radio button
    When Resident unchecks the primary person
    And Resident switched to dental benefits
    Then the primary person checkbox should be in unchecked status
    And Resident should also see the reason for ineligibility
    When Resident checks the primary person
    And Resident clicked on shop for new plan
    Then Resident should see primary person
