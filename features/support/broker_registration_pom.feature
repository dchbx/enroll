Feature: Broker Agency Registration

  Scenario: Primary Broker has not signed up on the HBX
    Given a CCA site exists with a benefit market
    When a Primary Broker visits the HBX Broker Registration form POM
    Given Primary Broker has not signed up as an HBX user
    Then Primary Broker should see the New Broker Agency form POM
    When Primary Broker enters personal information POM
    And Primary Broker enters broker agency information POM
    Then Primary Broker should see the registration submitted successful message