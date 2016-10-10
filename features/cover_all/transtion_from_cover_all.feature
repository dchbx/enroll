Feature: Transition from CoverAll to EnrollApp

  Scenario: Consumer becomes eligible for coverage through the exchange
    Given a family is enrolled in CoverAll DC
    And becomes eligible for coverage through the exchange
    When the admin selects the family through the CoverAll filter in the families index
    And selects "Transition to DC Health Link" from the actions menu
    Then the existing member/household info previously entered for CoverAll application will pre-populate the new EA application

  Scenario: Same plan selected for new EA coverage
    Given a family has elected to transition to exchange coverage from CoverAll
    And have selected to keep the same plan
    When they complete their application through EA
    Then the EDI transaction to Carriers will reference the same plan/policy
    And will have the new eligibility begin date and effective date
    And will have an indicator for on-exchange coverage
    And the old CoverAll enrollment will be terminated at the appropriate date
    And a Termination EDI transaction will be sent to the Carrier

  Scenario: New plan selected for new EA coverage
    Given a family has elected to transition to exchange coverage from CoverAll
    And have selected a new plan
    Then the EDI transaction will be no different than any standard enrollment transaction
    And the old CoverAll enrollment will be terminated at the appropriate date
    And a Termination EDI transaction will be sent to the Carrier
