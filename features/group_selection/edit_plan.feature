Feature: Edit Plan Button

  Background:
    Given a consumer exists
    And the consumer is logged in
    And consumer has a dependent in child relationship with age greater than 26
    And consumer has a dependent in spouse relationship with age greater than 26
    And consumer also has a health enrollment with primary person covered
    When consumer visits home page after successful ridp

  Scenario: Submit button disabled with date and "no" answered for "Are you sure?"
    When consumer clicks on the edit plan button
    Then consumer should see the edit plan page
    When consumer clicks on the Cancel Plan button
    And consumer selects "no" to are you sure
    And consumer selects a date
    Then the submit button should be disabled

  Scenario: Submit button disabled with date and and no answer for "Are you sure?"
    When consumer clicks on the edit plan button
    Then consumer should see the edit plan page
    When consumer clicks on the Cancel Plan button
    And consumer selects a date
    Then the submit button should be disabled

  Scenario Outline: Submit button disabled with no date
    When consumer clicks on the edit plan button
    Then consumer should see the edit plan page
    When consumer clicks on the Cancel Plan button
    And consumer selects "<answer>" to are you sure
    Then the submit button should be disabled

    Examples:
      | answer |
      | no     |
      | yes    |

  Scenario Outline: Consumer, EE with IVL coverage, or resident terminates plan
    Given consumer has a <secondary_role> secondary role
    When consumer clicks on the edit plan button
    Then consumer should see the edit plan page
    When consumer clicks on the Cancel Plan button
    Then consumer should see the calender
    And the submit button should be disabled
    When consumer selects a date
    And  consumer selects yes to are you sure
    Then the submit button should be enabled
    When consumer clicks the submit button
    Then the enrollment should be pending termination

    Examples:
      | secondary_role |
      | consumer |
      | resident |
      | employee |

  Scenario Outline: Consumer, EE with IVL coverage, or resident cancels plan
    Given consumer has a <secondary_role> secondary role
    When consumer's health enrollment has an effective date in the future
    When consumer clicks on the edit plan button
    And consumer clicks on the Cancel Plan button
    Then consumer should not see the calender
    When consumer selects yes to are you sure
    Then the submit button should be enabled
    When consumer clicks the submit button
    Then the enrollment should be canceled

    Examples:
      | secondary_role |
      | consumer |
      | resident |
      | employee |

  Scenario Outline: Edit plan button visibility on IVL enrollment tiles
    Given consumer should see my account page
    And the enrollment is in <state> state
    Then the consumer <visibility> see the edit plan button
    And the consumer should not see the make changes button

    Examples:
      | state                        | visibility |
      | coverage_selected            | should     |
      | auto_renewing                | should     |
      | unverified                   | should     |
      | renewing_coverage_selected   | should     |
      | transmitted_to_carrier       | should     |
      | coverage_termination_pending | should not |
      | coverage_terminated          | should not |
      | coverage_canceled            | should not |
      | coverage_expired             | should not |
