Feature: Consumer requests enrollment in CoverAll
  As a person who is aware in advance that he is not qualified for QHP through the
  exchange, and has not initialized an application through EA, he can request to
  be enrolled in CoverAll. The HBX admin can then enter their information and
  process their application through the families index page.


  Scenario: Consumer has requested to be enrolled in CoverAll
    Given a consumer has requested to be enrolled in Cover All by the HBX Admin
    When the Admin clicks the ' New CoverAll DC Application' link at the bottom of the Families Index View Page
    And enters the basic information for the consumer
    And selects which household members will be included in the plan
    And enters enroll in Cover All
    Then a notification appears stating that the enrollment in coverall has been submitted
