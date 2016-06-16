Feature: Binder transitions
  As an HBX admin I can help employers pay for their insurance.

  Background:
    Given a new employer, with insured employees, exists
    And an HBX admin exists
    And the HBX admin is logged in

  Scenario: HBX-Admin participation requirements checklist for new ER
    Given the HBX admin visits the Dashboard page
    And the HBX admin clicks the Binder Transition tab
    When the HBX admin selects the employer to confirm
    Then the HBX admin sees a checklist
      | checklist                                                              |
      | Minimum participation: ≥ 0.66 * (All enrolled + waived / All Eligible) |
      | At least one non-owner or owner family member must enroll (at renewal) |
      | Owner/owner family member flag: Can be self-attested                   |
      #| Binder premium amount and payment status verified by HBX               |

  Scenario: HBX-Admin confirms participation requirements for new ER
    #Given the employer meets requirements
    When the HBX admin visits the Dashboard page
    And the HBX admin has confirmed requirements for the employer
    #When the employer remits initial binder payment
    #And the DCHBX confirms binder payment has been received by third-party processor
    And the HBX admin has verified new (initial) Employer meets minimum participation requirements (2/3 rule)
    And a sufficient number of 'non-owner' employee(s) have enrolled and/or waived in Employer-sponsored benefits
    Then the initiate "Binder Paid" button will be active

  Scenario: HBX-Admin changes Employer state to Binder Paid for new ER
    #Given the employer meets requirements
    When the HBX admin visits the Dashboard page
    And the HBX admin has confirmed requirements for the employer
    #And the employer has remitted the initial binder payment
    And the HBX admin clicks the "Binder Paid" button
    Then then the Employer’s state transitions to "Binder Paid"
    #And the Group XML is generated for the Employer

  Scenario: HBX-Admin views transmit Group XML button for new ER
    When the HBX admin visits the Dashboard page
    And the HBX admin has confirmed requirements for the employer
    And the HBX admin clicks the "Binder Paid" button
    Then then the Employer’s state transitions to "Binder Paid"
    Then a button to transmit the Employer's Group XML will be active

  Scenario: HBX-Admin transmits Group XML for new ER
    When the HBX admin visits the Dashboard page
    And the HBX admin has confirmed requirements for the employer
    And the HBX admin clicks the "Binder Paid" button
    Then then the Employer’s state transitions to "Binder Paid"
    Then a button to transmit the Employer's Group XML will be active
    When the HBX-Admin clicks the button to transmit the Employer's Group XML
    Then the appropriate XML file is generated and transmitted


  Scenario: HBX-Admin participation requirements checklist for renewing ER
    Given the employer is renewing
    And the HBX admin visits the Dashboard page
    And the HBX admin clicks the Binder Transition tab
    When the HBX admin selects the employer to confirm
    Then the HBX admin sees a checklist
      | checklist                                                              |
      | Minimum participation: ≥ 0.66 * (All enrolled + waived / All Eligible) |
      | At least one non-owner or owner family member must enroll (at renewal) |
      | Owner/owner family member flag: Can be self-attested                   |

  Scenario: HBX-Admin confirms participation requirements for renewing ER
    Given the employer is renewing
    #And the employer meets requirements
    When the HBX admin visits the Dashboard page
    And the HBX admin has confirmed requirements for the employer
    #And the employer has remitted the initial binder payment
    #Then the HBX-Admin can utilize the “Transmit EDI” button
