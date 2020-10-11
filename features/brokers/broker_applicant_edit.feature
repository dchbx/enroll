Feature: HBX Admin Edits a Broker Applicant

  Scenario: Primary Broker has not signed up on the HBX
    Given a CCA site exists with a benefit market
    Given all permissions are present
    And the Plans exist
    And there is a Broker Agency exists for District Brokers Inc
    And the broker Max Planck is primary broker for District Brokers Inc

    Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
    # Skipped the steps here due to constant intermittent failures with clicking links
    And HBX Admin visits the Edit Broker Applicant page for Max Planck of agency District Brokers Inc
    And HBX Admin edits the broker application and clicks update
    Then the HBX Admin should see a success message that the broker application was successfully updated