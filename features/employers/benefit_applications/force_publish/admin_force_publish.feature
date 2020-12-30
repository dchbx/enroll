Feature: As an admin user I should have the ability to extend the OE
  of a given Employer with an extended enrollment.

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    And there is an employer ABC Widgets
    And initial employer ABC Widgets has draft benefit application

  Scenario Outline: As an HBX Staff with Super Admin subroles I should <action> force publish button based on <date_to_compare_with> and publish_due_day_of_month of benefit application

    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    When the system date is <system_date_value> than the <date_to_compare_with>
    And the system date is <date_compare> than the publish_due_day_of_month
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer
    Then the user will <action> the Force Publish button

    Examples:
      | system_date_value | date_to_compare_with                 | date_compare | action  |
      | greater           | earliest_start_prior_to_effective_on | less         | not see |
      | less              | monthly_open_enrollment_end_on       | greater      | see     |

  Scenario: Draft application published between submission deadline & application effective date
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the system date is less than the earliest_start_prior_to_effective_on
    And the user is on the Employer Index of the Admin Dashboard
    When ABC widgets FTE count is less than or equal to shop:small_market_employee_count_maximum
    And ABC widgets primary address state is MA
    And the user clicks Action for that Employer
    Then the user will see the Force Publish button
    And the user clicks on Force Publish button
    And the user clicks submit to confirm force publish
    Then the force publish successful message should be displayed

  Scenario Outline: Draft application published between submission deadline & application effective date
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the system date is less than the earliest_start_prior_to_effective_on
    And the user is on the Employer Index of the Admin Dashboard
    And ABC widgets FTE count is <compare_fte> to shop:small_market_employee_count_maximum
    And ABC widgets primary address state <state_check> MA
    And the user clicks Action for that Employer
    And the user clicks on Force Publish button
    And the user clicks submit to confirm force publish
    Then a <compare_fte> warning message will appear
    # And ask to confirm intention to publish.

    Examples:
      | compare_fte        | state_check |
      | more than          | is          |
      | more than          | is not      |
      | less than or equal | is not      |


  Scenario: Application force published with eligibility warnings should go to publish pending state
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the system date is less than the earliest_start_prior_to_effective_on
    And the user is on the Employer Index of the Admin Dashboard
    And ABC widgets FTE count is more than to shop:small_market_employee_count_maximum
    And ABC widgets primary address state is not MA
    And the user clicks Action for that Employer
    And the user clicks on Force Publish button
    And the user clicks submit to confirm force publish
    Then a less than or equal warning message will appear
    And the user clicks force publish
    Then the user will see application ineligible message
