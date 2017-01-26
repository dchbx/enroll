Feature: CoverAll reporting

  Background:
    Given an individual/family is enrolled under CoverAll DC

  Scenario: CoverAll enrollments are excluded from monthly CMS/IRS reporting
    When the monthly job runs for the CMS/IRS report
    Then the CoverAll DC enrollments will be excluded

  Scenario: CoverAll enrollments are excluded from annual 1095 reporting
    When the annual 1095 job runs
    Then the CoverAll DC enrollments will be excluded

  Scenario:  CoverAll enrollments are included in monthly Carrier reconciliation
    When the monthly Carrier audit files are generated
    Then the CoverAll DC enrollments will be included and designated as such
