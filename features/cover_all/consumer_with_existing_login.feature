Feature: Consumer with existing login
  As a consumer without an enrollment but having created an account through EA,
  when the the HBX admin enrolls me in CoverAll, my role should change from consumer_rolw
  to resident_role. Also when I attempt to log into EA with my original
  credentials I should see that I am enrolled in CoverAll.

  Scenario: HBX admin enrolls consumer with login in CoverAll
    Given I have already created an account in EA
    # TODO verify that person has consumer_role
    And the HBX admin enrolls me in CoverAll
    When I enter my login credentials
    Then I should see that I have been entered in CoverAll
    # TODO assert new role is resident_role and consumer_role returns nil
    And my my new role should be "resident_role"
