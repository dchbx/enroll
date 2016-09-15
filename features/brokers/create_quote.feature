Feature: Create Employee Roster
  In order for Brokers to give a quote to employers
  The Broker should be able to add emloyees
  And Generate a quote

  Scenario: Broker should be able to add employee to employee roster
    Given that a broker exists
    And the broker is signed in
    When he visits the Roster Quoting tool
    And click on the New Quote button
    Then the broker enters the quote effective date
    And broker enters valid information
    When the broker clicks on the Save Changes button
    Then the broker should see a successful message

  Scenario: Broker should be able to add employees to the employee roster using Upload Employee Roster button
    Given that a broker exists
    And the broker is signed in
    When he visits the Roster Quoting tool
    And click on the New Quote button
    And click on the Upload Employee Roster button
    When the broker clicks on the Select File to Upload button
    Then the broker clicks upload button
    Then the broker enters the quote effective date
    And the broker should see the data in the table
    When the broker clicks on the Save Changes button
    Then the broker should see a successful message
    And Broker logs out

  Scenario: Broker should be able to delete an existing Roster
    Given that a broker exists
    And the broker is signed in
    When he visits the Roster Quoting tool
    And click on the New Quote button
    Then the broker enters the quote effective date
    And broker enters valid information
    When the broker clicks on the Save Changes button
    Then the broker should see a successful message
    And the broker clicks on Back to Quotes button
    Then the broker clicks Actions dropdown
    When the broker clicks delete
    Then the broker sees the confirmation
    And the broker clicks Delete Quote
    Then the quote should be deleted
    And Broker logs out

  Scenario: Broker should be able to assign benefit group to a family
    Given that a broker exists
    And the broker is signed in
    When he visits the Roster Quoting tool
    And click on the New Quote button
    Then the broker enters the quote effective date
    Then broker enters valid information
    And adds a new benefit group
    Then the broker assigns the benefit group to the family
    And the broker saves the quote
    And Broker logs out

  Scenario: Broker should be able to create a quote
    Given that a broker exists
    And the Plans exist
    And the broker is signed in
    When he visits the Roster Quoting tool
    And click on the New Quote button
    Then the broker enters the quote effective date
    And broker enters valid information
    When the broker clicks on the Save Changes button
    Then the broker should see a successful message
    And the broker clicks on Back to Quotes button
    When the broker clicks on quote
    Then the broker enters Employer Contribution percentages for health plan
    And the broker filters health plans
    Then the broker clicks Compare Costs for health plans
    When the broker selects the Reference Health Plan
    Then the broker clicks Publish Quote button
    And the broker sees that the Quote is published
    And Broker logs out

  Scenario: Broker should create a quote with health and dental plans
    Given that a broker exists
    And the Plans exist
    And the broker is signed in
    When he visits the Roster Quoting tool
    And click on the New Quote button
    Then the broker enters the quote effective date
    And broker enters valid information
    When the broker clicks on the Save Changes button
    Then the broker should see a successful message
    And the broker clicks on Back to Quotes button
    When the broker clicks on quote
    Then the broker enters Employer Contribution percentages for health plan
    And the broker filters health plans
    Then the broker clicks Compare Costs for health plans
    And the broker selects the Reference Health Plan
    When the broker clicks Dental Features
    Then the broker enters Employer Contribution percentages for dental plan
    And the broker filters dental plans
    Then the broker clicks Compare Costs for dental plans
    And the broker selects the Reference Dental Plan
    Then the broker clicks Publish Quote button
    And the broker sees that the Quote is published
    And Broker logs out
