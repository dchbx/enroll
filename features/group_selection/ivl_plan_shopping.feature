Feature: IVL plan purchase

  Scenario: when IVL purchase plan for self & dependent
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in "child" relationship
    And consumer visits home page after successful ridp
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    And ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer clicked on shop for new plan
    Then consumer should see both dependent and primary

  Scenario: when IVL purchase plan only for dependent
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in "child" relationship
    And consumer visits home page after successful ridp
    And consumer clicked on "Married" qle
    And I select a past qle date
    Then I should see confirmation and continue
    And ivl clicked continue on household info page
    Then consumer should see all the family members names
    And consumer unchecks the primary person
    And consumer clicked on shop for new plan
    Then consumer should only see the dependent name
    
