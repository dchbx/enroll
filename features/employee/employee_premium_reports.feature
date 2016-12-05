Feature: Validation of Adding Datatables to premium billing reports

  Scenario: Employer should able to click on View Enrolment Reports with no records

    Given Hbx Admin exists

    When login to HBX portal with email: admin@dc.gov and password: aA1!aA1!aA1!

    Then admin login's

    And Click on Employers Link

    Then Click on Turner Agency, Inc Link

    And Click on View Enrollment Reports Link

    Then display no records

  Scenario: Employer should able to click on View Enrolment Reports with active benefit plan 

    Given Hbx Admin exists

    When login to HBX portal with email: admin@dc.gov and password: aA1!aA1!aA1!

    Then admin login's

    And Click on Employers Link

    Then Click on Acme Inc. Link

    And Click on View Enrollment Reports Link

    Then active benefit plan employees displayed