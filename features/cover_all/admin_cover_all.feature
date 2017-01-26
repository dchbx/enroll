Feature: Admin for Cover All

  Scenario: Consumer state transitions triggers report for admin
    Given a consumer has failed to provide the documentation for his eligibility
    And his eligibility state is verification_period_ended
    # need to know enrollment state at this point
    And his enrollment state is
    When the verification period expires
    Then a monthly job will run to pull the TBD eligibility event
    And will generate a report for the Admin
    And the report will contain information for all family members on the EA enrollment
    And it will include demographic information for the household
    And it will have the event name
    And it will have the event date #should be the verification period expiration date
    # what are the required verifications
    And it will have a status listing of all required verifications

  Scenario: Admin receives monthly report of newly transitioned applicants
    Given the admin has received the NAME_OF_REPORT
    # what are the criteria they will use to determine for Cover All
    When the admin determines it is appropriate to transition the enrollment to Cover All
    Then the admin will select the "Trannstion to CoverAll DC" tab in the families index
    And the effective dates will follow the same logic as of those for non-self-attested SEP's
    And any APTC/CSR will be removed from the EA enrollment as of the effective date for CoverAll transition

  Scenario: CoverAll event triggers EDI files to Carrier
    Given a completed application through EA was transmitted to the carrier
    And the applicant's eligibility transtioned to verification_period_ended
    When the Admin transitions the eligibility/enrollment to CoverAll DC
    Then  a termination file is generated and sent to the Carrier for the current EA enrollment with the appropriate term date
    And a new enrollment is transmitted with the new eligibility/effective dates as CoverAll
    And it is void of any APTC/CSR amounts
    And it has a designator in the 2750 loop to indicate CoverAll DC
    And it references the old plan information so as to not reset any accumulators
