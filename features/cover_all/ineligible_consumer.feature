Feature: Ineligible Consumer
  As a consumer, when I am found to be ineligible for Marketplace coverage through
  the enroll app, then my state should change to fill_in_the_blank_here

  Scenario: Consumer found ineligible for Marketplace coverage
    Given I am a consumer
    And I have submitted an eligibility application
    And I have completed my plan selection
    And have outstanding verifications
    # what is the state before this
    Then my eligibility transitions to verification_outstanding state
    And my enrollment transitions to enrolled_contingent state


  Scenario: Verification period expires without proper documentation being submitted
    Given I am a consumer
    And I am in the verification_outstanding state
    And my enrollment is in the enrolled_contingent state
    # what are the bounds on the verification period
    When the verification period expires
    And I have not submitted the proper documentation
    Then my eligibility state transitions to verification_period_ended
    # what will be the new enrollment state
    And my enrollment transitions to

  Scenario: consumer is already aware they are ineligibly for QHP through EA
    Given I am a consumer and have not begun an application in EA
    And I am ineligible to purchase QHP through the Marketplace
    # how do I notify the exchange? phone? email?
    When I notify the Exchange that I wish to elect CoverAll participation
    Then the Admin will click the ' New CoverAll DC Application' link at the bottom of the Families Index View Page
    # unclear on what the admin will enter and what will be the applicant's responsibility
