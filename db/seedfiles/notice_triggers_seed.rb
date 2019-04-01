puts "*"*80
puts "::: Cleaning ApplicationEventKinds :::"
ApplicationEventKind.delete_all

shop_notice_triggers = []

ivl_notice_triggers = [
  {
    hbx_id: 'VerificationBacklog',
    title: 'Documents needed to confirm eligibility for your plan',
    description: 'Should be triggered for thoso who completed Enroll App application but verifications pending',
    resource_name: 'consumer_role',
    event_name: 'verifications_backlog',
    notice_triggers: [
      {
        name: 'Outstanding Verification Notification',
        notice_template: 'notices/ivl/verifications_backlog_notice',
        notice_builder: 'IvlNotices::ReminderNotice',
        mpi_indicator: 'MPI_IVLV5B',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'IVL_DR1',
    title: 'Reminder - You Must Submit Documents by the Deadline to Keep Your Insurance',
    description: 'After 10 days passed, notice to be sent to Consumers informing them of the outstanding verifications',
    resource_name: 'consumer_role',
    event_name: 'first_verifications_reminder',
    notice_triggers: [
      {
        name: 'First Outstanding Verification Notification',
        notice_template: 'notices/ivl/documents_verification_reminder',
        notice_builder: 'IvlNotices::ReminderNotice',
        mpi_indicator: 'IVL_DR1',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'IVL_DR2',
    title: "Don't Forget - You Must Submit Documents by the Deadline to Keep Your Insurance",
    description: 'After 25 days passed, notice to be sent to Consumers informing them of the outstanding verifications',
    resource_name: 'consumer_role',
    event_name: 'second_verifications_reminder',
    notice_triggers: [
      {
        name: 'Second Outstanding Verification Notification',
        notice_template: 'notices/ivl/documents_verification_reminder',
        notice_builder: 'IvlNotices::ReminderNotice',
        mpi_indicator: 'IVL_DR2',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'IVL_DR3',
    title: 'Time Sensitive - You Must Submit Documents by the Deadline to Keep Your Insurance',
    description: 'After 50 days passed, notice to be sent to Consumers informing them of the outstanding verifications',
    resource_name: 'consumer_role',
    event_name: 'third_verifications_reminder',
    notice_triggers: [
      {
        name: 'Third Outstanding Verification Notification',
        notice_template: 'notices/ivl/documents_verification_reminder',
        notice_builder: 'IvlNotices::ReminderNotice',
        mpi_indicator: 'IVL_DR3',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'IVL_DR4',
    title: 'Final Notice - You Must Submit Documents by the Deadline to Keep Your Insurance',
    description: 'After 65 days passed, notice to be sent to Consumers informing them of the outstanding verifications',
    resource_name: 'consumer_role',
    event_name: 'fourth_verifications_reminder',
    notice_triggers: [
      {
        name: 'Fourth Outstanding Verification Notification',
        notice_template: 'notices/ivl/documents_verification_reminder',
        notice_builder: 'IvlNotices::ReminderNotice',
        mpi_indicator: 'IVL_DR4',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'IVL_PRE_1',
    title: 'Update your information at DC Health Link by October 15',
    description: 'Notice to be sent out to individuals with UQHP(Unassisted)',
    resource_name: 'consumer_role',
    event_name: 'projected_eligibility_notice_1',
    notice_triggers: [
      {
        name: 'September Projected Renewal Notice',
        notice_template: 'notices/ivl/projected_eligibility_notice',
        notice_builder: 'IvlNotices::IvlRenewalNotice',
        mpi_indicator: 'IVL_PRE',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'IVL_PRE_2',
    title: 'Update your information at DC Health Link by October 15',
    description: 'Notice to be sent out to individuals with AQHP(Assisted)',
    resource_name: 'consumer_role',
    event_name: 'projected_eligibility_notice_2',
    notice_triggers: [
      {
        name: 'September Projected Renewal Notice',
        notice_template: 'notices/ivl/projected_eligibility_notice',
        notice_builder: 'IvlNotices::SecondIvlRenewalNotice',
        mpi_indicator: 'IVL_PRE',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'IVL_FEL_AQHP',
    title: 'Your Final Eligibility Results, Plan, And Option To Change Plans',
    description: 'Final Eligibility Notice will be sent to all AQHP individuals',
    resource_name: 'consumer_role',
    event_name: 'final_eligibility_notice_aqhp',
    notice_triggers: [
      {
        name: 'Final Eligibility Notice for AQHP individuals',
        notice_template: 'notices/ivl/final_eligibility_notice_aqhp',
        notice_builder: 'IvlNotices::FinalEligibilityNoticeAqhp',
        mpi_indicator: 'IVL_FEL',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'IVL_FEL_UQHP',
    title: 'Your Final Eligibility Results, Plan, And Option To Change Plans',
    description: 'Final Eligibility Notice will be sent to all UQHP individuals',
    resource_name: 'consumer_role',
    event_name: 'final_eligibility_notice_uqhp',
    notice_triggers: [
      {
        name: 'Final Eligibility Notice for UQHP individuals',
        notice_template: 'notices/ivl/final_eligibility_notice_uqhp',
        notice_builder: 'IvlNotices::FinalEligibilityNoticeUqhp',
        mpi_indicator: 'IVL_FEL',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'IVL_FRE',
    title: 'Review Your Insurance Plan Enrollment and Pay Your Bill Now',
    description: 'Final Eligibility Notice will be sent to all UQHP/AQHP individuals',
    resource_name: 'consumer_role',
    event_name: 'final_eligibility_notice_renewal_uqhp',
    notice_triggers: [
        {
            name: 'Final Eligibility Notice for UQHP/AQHP individuals',
            notice_template: 'notices/ivl/final_eligibility_notice_uqhp_aqhp',
            notice_builder: 'IvlNotices::FinalEligibilityNoticeRenewalUqhp',
            mpi_indicator: 'IVL_FRE',
            notice_trigger_element_group: {
                market_places: ['individual'],
                primary_recipients: ["consumer"],
                primary_recipient_delivery_method: ["secure_message", "paper"],
                secondary_recipients: []
            }
        }
    ]
  },

  {
    hbx_id: 'IVL_FRE',
    title: 'Review Your Insurance Plan Enrollment and Pay Your Bill Now',
    description: 'Final Eligibility Notice will be sent to all UQHP/AQHP individuals',
    resource_name: 'consumer_role',
    event_name: 'final_eligibility_notice_renewal_aqhp',
    notice_triggers: [
        {
            name: 'Final Eligibility Notice for UQHP/AQHP individuals',
            notice_template: 'notices/ivl/final_eligibility_notice_uqhp_aqhp',
            notice_builder: 'IvlNotices::FinalEligibilityNoticeRenewalAqhp',
            mpi_indicator: 'IVL_FRE',
            notice_trigger_element_group: {
                market_places: ['individual'],
                primary_recipients: ["consumer"],
                primary_recipient_delivery_method: ["secure_message", "paper"],
                secondary_recipients: []
            }
        }
    ]
    },

  {
    hbx_id: 'IVLR2',
    title: '2017 Health Insurance Coverage and Preliminary Renewal Information',
    description: 'Notice to be sent out to individuals staying in APTC only',
    resource_name: 'consumer_role',
    event_name: 'ivl_renewal_notice_2',
    notice_triggers: [
      {
        name: 'September Projected Renewal Notice',
        notice_template: 'notices/ivl/projected_eligibility_notice',
        notice_builder: 'IvlNotices::SecondIvlRenewalNotice',
        mpi_indicator: 'IVL_PRE',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'IVLR3',
    title: '2017 Health Insurance Coverage and Preliminary Renewal Information',
    description: 'Notice to be sent out to individuals moving from APTC to Medicaid',
    resource_name: 'consumer_role',
    event_name: 'ivl_renewal_notice_3',
    notice_triggers: [
      {
        name: 'September Projected Renewal Notice',
        notice_template: 'notices/ivl/projected_eligibility_notice',
        notice_builder: 'IvlNotices::SecondIvlRenewalNotice',
        mpi_indicator: 'IVL_PRE',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'IVLR4',
    title: '2017 Health Insurance Coverage and Preliminary Renewal Information',
    description: 'Notice to be sent out to individuals moving from APTC to UQHP',
    resource_name: 'consumer_role',
    event_name: 'ivl_renewal_notice_4',
    notice_triggers: [
      {
        name: 'September Projected Renewal Notice',
        notice_template: 'notices/ivl/projected_eligibility_notice',
        notice_builder: 'IvlNotices::SecondIvlRenewalNotice',
        mpi_indicator: 'IVL_PRE',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'IVLR8',
    title: '2017 Insurance Renewal Notice and Opportunity to Change Plans',
    description: 'Notice to be sent out to individuals staying on UQHP',
    resource_name: 'consumer_role',
    event_name: 'ivl_renewal_notice_8',
    notice_triggers: [
      {
        name: 'September Projected Renewal Notice - UQHP',
        notice_template: 'notices/ivl/IVLR8_UQHP_to_UQHP',
        notice_builder: 'IvlNotices::VariableIvlRenewalNotice',
        mpi_indicator: 'MPI_IVLR8',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'IVLR9',
    title: 'Your 2017 Final Insurance Enrollment Notice',
    description: 'Notice to be sent out to people enrolled in 2017 coverage who have enrolled by December',
    resource_name: 'consumer_role',
    event_name: 'ivl_renewal_notice_9',
    notice_triggers: [
      {
        name: 'December Final Insurance Enrollment Notice',
        notice_template: 'notices/ivl/IVLR9_UQHP_final_renewal_december',
        notice_builder: 'IvlNotices::NoAppealVariableIvlRenewalNotice',
        mpi_indicator: 'MPI_IVLR9',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'IVLR10',
    title: 'Your 2017 Final Insurance Enrollment Notice',
    description: 'Notice to be sent out to people enrolled in 2017 assisted coverage who have enrolled by December',
    resource_name: 'consumer_role',
    event_name: 'ivl_renewal_notice_10',
    notice_triggers: [
      {
        name: 'December Final Insurance Enrollment Notice',
        notice_template: 'notices/ivl/IVLR10_AQHP_final_renewal',
        notice_builder: 'IvlNotices::NoAppealVariableIvlRenewalNotice',
        mpi_indicator: 'MPI_IVLR10',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'IVL_CAP',
    title: 'Important Tax Information about your Catastrophic Health Coverage',
    description: 'Notice to be sent out to all the people enrolled in Catastrophic plan in 2017 for at least a day',
    resource_name: 'consumer_role',
    event_name: 'final_catastrophic_plan',
    notice_triggers: [
      {
        name: 'Final Catastrophic Plan Notice',
        notice_template: 'notices/ivl/final_catastrophic_plan_letter',
        notice_builder: 'IvlNotices::FinalCatastrophicPlanNotice',
        mpi_indicator: 'IVL_CAP',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'IVL_ELA',
    title: 'ACTION REQUIRED - HEALTH COVERAGE ELIGIBILITY',
    description: 'Notice will be sent to all the individuals eligible for coverage through DC Health Link',
    resource_name: 'consumer_role',
    event_name: 'eligibility_notice',
    notice_triggers: [
      {
        name: 'Eligibilty Notice',
        notice_template: 'notices/ivl/eligibility_notice',
        notice_builder: 'IvlNotices::EligibilityNoticeBuilder',
        mpi_indicator: 'IVL_ELA',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'IVL_NEL',
    title: 'IMPORTANT NOTICE - INELIGIBLE FOR COVERAGE THROUGH DC HEALTH LINK',
    description: 'Notice will be sent to the household if everyone in the household is ineligible',
    resource_name: 'consumer_role',
    event_name: 'ineligibility_notice',
    notice_triggers: [
      {
        name: 'Ineligibilty Notice',
        notice_template: 'notices/ivl/ineligibility_notice',
        notice_builder: 'IvlNotices::IneligibilityNoticeBuilder',
        mpi_indicator: 'IVL_NEL',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'IVL_ENR',
    title: 'Your Health or Dental Plan Enrollment and Payment Deadline',
    description: 'Notice will be sent to families after their enrollment is done.',
    resource_name: 'consumer_role',
    event_name: 'enrollment_notice',
    notice_triggers: [
      {
        name: 'Enrollment Notice',
        notice_template: 'notices/ivl/enrollment_notice',
        notice_builder: 'IvlNotices::EnrollmentNoticeBuilder',
        mpi_indicator: 'IVL_ENR',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'IVL_ENR',
    title: 'Your Health or Dental Plan Enrollment and Payment Deadline',
    description: 'This is an Enrollment Notice and is sent for people who got enrolled in a Particular Date Range',
    resource_name: 'consumer_role',
    event_name: 'enrollment_notice_with_date_range',
    notice_triggers: [
      {
        name: 'Enrollment Notice',
        notice_template: 'notices/ivl/enrollment_notice',
        notice_builder: 'IvlNotices::EnrollmentNoticeBuilderWithDateRange',
        mpi_indicator: 'IVL_ENR',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'IVL_TAX',
    title: 'Your 1095-A Health Coverage Tax Form',
    description: 'Notice to be sent out to all the people who got 1095a form for the year 2017',
    resource_name: 'consumer_role',
    event_name: 'ivl_tax_cover_letter_notice',
    notice_triggers: [
      {
        name: '1095A Tax Cover Letter Notice',
        notice_template: 'notices/ivl/ivl_tax_notice',
        notice_builder: 'IvlNotices::IvlTaxNotice',
        mpi_indicator: 'IVL_TAX',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'IVL_BV',
    title: 'You Must Submit Documents by the Deadline to Keep Your Insurance',
    description: 'This is an Backlog Notice and is sent for people need to submit their documents',
    resource_name: 'consumer_role',
    event_name: 'ivl_backlog_verification_notice_uqhp',
    notice_triggers: [
      {
        name: 'Backlog Notice',
        notice_template: 'notices/ivl/ivl_backlog_verification_notice_uqhp',
        notice_builder: 'IvlNotices::IvlBacklogVerificationNoticeUqhp',
        mpi_indicator: 'IVL_BV',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'IVL_CDC',
    title: 'Your Insurance through DC Health Link Has Changed to Cover All DC',
    description: 'This is an Transition Notice and is sent for people who are moved to Coverall DC',
    resource_name: 'consumer_role',
    event_name: 'ivl_to_coverall_transition_notice',
    notice_triggers: [
      {
        name: 'Ivl to Coverall Transition Notice',
        notice_template: 'notices/ivl/ivl_to_coverall_notice',
        notice_builder: 'IvlNotices::IvlToCoverallTransitionNoticeBuilder',
        mpi_indicator: 'IVL_CDC',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'IVL_DCH',
    title: 'Your Insurance through Cover All DC Has Changed to DC Health Link',
    description: 'This is an Transition Notice and is sent for people who are moved to DC HEALTH LINK',
    resource_name: 'consumer_role',
    event_name: 'coverall_to_ivl_transition_notice',
    notice_triggers: [
      {
        name: 'Coverall to IVL Transition Notice',
        notice_template: 'notices/ivl/coverall_to_ivl_notice',
        notice_builder: 'IvlNotices::CoverallToIvlTransitionNoticeBuilder',
        mpi_indicator: 'IVL_DCH',
        notice_trigger_element_group: {
          market_places: ['individual'],
          primary_recipients: ["consumer"],
          primary_recipient_delivery_method: ["secure_message", "paper"],
          secondary_recipients: []
        }
      }
    ]
  }
]

shop_notice_triggers.each do |trigger_params|
  ApplicationEventKind.create(trigger_params)
end

ivl_notice_triggers.each do |trigger_params|
  ApplicationEventKind.create(trigger_params)
end
