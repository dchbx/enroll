Feature: Broker Agency Registration with POM

 Scenario: Primary Broker has not signed up on the HBX
    Given a CCA site exists with a benefit market
    When Primary Broker visits the HBX Broker Registration form POM
    Given Primary Broker has not signed up as an HBX user
    Then Primary Broker should see the New Broker Agency form POM
    When Primary Broker enters personal information POM
    And Primary Broker enters broker agency information for SHOP markets
    And Primary Broker enters office location for default_office_location
    Then Primary Broker should see broker registration successful message