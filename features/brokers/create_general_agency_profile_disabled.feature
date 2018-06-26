@general_agency_disabled
Feature: Create General Agency and General Agency Staff Role
  Scenario: General Agency has not signed up on the HBX
    When General Agency visit the main portal
      Then General Agency should not see the New General Agency form
  
