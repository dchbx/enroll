Feature: IVL plan purchase

  Scenario: when IVL purchase plan for self & dependent
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer clicked on shop for new plan
    Then consumer should see both dependent and primary

  Scenario: when IVL purchase plan only for dependent
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    When consumer unchecks the primary person
    And consumer clicked on shop for new plan
    Then consumer should only see the dependent name

  Scenario: IVL having an ineligible family member & doing plan shop
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer should see the ineligible family member disabled and unchecked
    And consumer should see the eligible family member enabled and checked
    And consumer should also see the reason for ineligibility
    And consumer should see the dental radio button
    When consumer unchecks the primary person
    And consumer switched to dental benefits
    Then the primary person checkbox should be in unchecked status
    And consumer should also see the reason for ineligibility
    When consumer checks the primary person
    And consumer clicked on shop for new plan
    Then consumer should see primary person

  Scenario: when individual purchases dental plan for self & dependent and tries to filter by Low/High
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age less than 26
    And consumer has successful ridp
    When consumer visits home page
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    When ivl clicked continue on household info page
    Then consumer should see all the family members names
    And individual selects dental for coverage kind
    And consumer clicked on shop for new plan
    Then consumer should see both dependent and primary
    And individual selects high for metal level plan and metal level box appears selected