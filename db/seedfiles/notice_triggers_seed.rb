puts "*"*80
puts "::: Cleaning ApplicationEventKinds :::"
ApplicationEventKind.delete_all

shop_notice_triggers = [
  {
    hbx_id: 'SHOP1A',
    title: 'Initial Employer SHOP Application Approval',
    description: 'ER application requirements met SHOP participation approved',
    resource_name: 'employer',
    event_name: 'application_accepted',
    notice_triggers: [
      {
        name: 'Employer notice trigger',
        notice_template: 'notices/shop_employer_notices/1a_application_approval',
        notice_builder: 'ShopEmployerNotices::EmployerRenewalNotice',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP1B',
    title: 'Request for Clarifying Documentation',
    description: 'User has 30 calendar days to respond to this notice from the notice date',
    resource_name: 'employer',
    event_name: 'application_declined',
    notice_triggers: [
      {
        name: 'Employer notice trigger',
        notice_template: 'notices/shop_employer_notices/1b_request_documents',
        notice_builder: 'ShopEmployerNotices::EmployerRenewalNotice',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP1C',
    title: 'Approval of Employer SHOP Application after Request for Clarifying Documentation',
    description: 'ER application requirements met SHOP participation approved',
    resource_name: 'employer',
    event_name: 'benefit_coverage_initial_binder_paid',
    notice_triggers: [
      {
        name: 'Employer notice trigger',
        notice_template: 'notices/shop_employer_notices/1c_application_approval',
        notice_builder: 'ShopEmployerNotices::EmployerRenewalNotice',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D002',
    title: 'Employer Approval Notice',
    description: 'Application to Offer Group Health Coverage in DC Health Link',
    resource_name: 'employer',
    event_name: 'initial_employer_approval',
    notice_triggers: [
      {
        name: 'Initial Employer SHOP Approval Notice',
        notice_template: 'notices/shop_employer_notices/2_initial_employer_approval_notice',
        notice_builder: 'ShopEmployerNotices::InitialEmployerEligibilityNotice',
        mpi_indicator: 'SHOP_D002',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP2B',
    title: 'Employer Denial Notice',
    description: 'Application to Offer Group Health Coverage in DC Health Link',
    resource_name: 'employer',
    event_name: 'initial_employer_denial',
    notice_triggers: [
      {
        name: 'Denial of Initial Employer Application/Request for Clarifying Documentation',
        notice_template: 'notices/shop_employer_notices/2_initial_employer_denial_notice',
        notice_builder: 'ShopEmployerNotices::InitialEmployerDenialNotice',
        mpi_indicator: 'MPI_SHOP2B',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'DRG006',
    title: 'Plan Offerings Finalized',
    description: 'Application to Offer Group Health Coverage in DC Health Link when an Employer publishes PlanYear',
    resource_name: 'employer',
    event_name: 'planyear_renewal_3a',
    notice_triggers: [
      {
        name: 'PlanYear Renewal',
        notice_template: 'notices/shop_employer_notices/3a_employer_plan_year_renewal',
        notice_builder: 'ShopEmployerNotices::RenewalEmployerEligibilityNotice',
        mpi_indicator: 'MPI_DRG006',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'DRG007',
    title: 'Plan Offerings Finalized',
    description: 'Application to Offer Group Health Coverage in DC Health Link when an Employer PlanYear is force published',
    resource_name: 'employer',
    event_name: 'planyear_renewal_3b',
    notice_triggers: [
      {
        name: 'PlanYear Renewal Auto-Published',
        notice_template: 'notices/shop_employer_notices/3b_employer_plan_year_renewal',
        notice_builder: 'ShopEmployerNotices::RenewalEmployerEligibilityNotice',
        mpi_indicator: 'MPI_DRG007',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'SHOP_Out_of_pocket_notice',
    title: 'Plan Match Health Plan Comparison Tool – Instructions for Your Employees',
    description: 'Out of pocket calculator notifier',
    resource_name: 'employer',
    event_name: 'out_of_pocker_url_notifier',
    notice_triggers: [
      {
        name: 'Out of pocket Notice',
        notice_template: "notices/shop_employer_notices/out_of_pocket_notice.html.erb",
        notice_builder: 'ShopEmployerNotices::OutOfPocketNotice',
        mpi_indicator: 'MPI',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: [""],
          primary_recipient_delivery_method: ["email"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'SHOP5',
    title: 'Group Renewal Available',
    description: 'Notice will be sent to the Renewal Groups three months prior to their plan year renewing',
    resource_name: 'employer',
    event_name: 'group_renewal_5',
    notice_triggers: [
      {
        name: 'Group Renewal Notice',
        notice_template: 'notices/shop_employer_notices/5_employer_renewal_notice',
        notice_builder: 'ShopEmployerNotices::EmployerRenewalNotice',
        mpi_indicator: 'MPI_SHOP5',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'SHOP6',
    title: 'Welcome to DC Health Link, Group Renewal Available',
    description: 'Renewing Your Health Insurance Coverage for Your Small Business on November 1, 2016',
    resource_name: 'employer',
    event_name: 'conversion_group_renewal',
    notice_triggers: [
      {
        name: 'Conversion, Group Renewal Available',
        notice_template: 'notices/shop_employer_notices/6_conversion_group_renewal_notice',
        notice_builder: 'ShopEmployerNotices::EmployerRenewalNotice',
        mpi_indicator: 'MPI_SHOP6',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP6',
    title: 'Action Needed – Add all Eligible Employees to your Roster',
    description: 'This notice goes to all the employers with zero employees on roster when published',
    resource_name: 'employer',
    event_name: 'zero_employees_on_roster',
    notice_triggers: [
      {
        name: 'Zero Employees on Rotser',
        notice_template: 'notices/shop_employer_notices/notice_for_employers_with_zero_employees_on_roster',
        notice_builder: 'ShopEmployerNotices::ZeroEmployeesOnRoster',
        mpi_indicator: 'MPI_SHOP6',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP8A',
    title: 'Your Health Plan Open Enrollment Period has Begun',
    description: 'All the employees that are active in coverage and have an auto-renewal plan option available.',
    resource_name: 'employee_role',
    event_name: 'employee_open_enrollment_auto_renewal',
    notice_triggers: [
      {
        name: 'Renewal Open Enrollment available for Employee',
        notice_template: 'notices/shop_employee_notices/8a_renewal_open_enrollment_notice_for_employee',
        notice_builder: 'ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal',
        mpi_indicator: 'MPI_SHOP8A',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP8B',
    title: 'Your Health Plan Open Enrollment Period has Begun',
    description: 'All employees that enrolled the previous year and do not have an auto-renewal plan option available.',
    resource_name: 'employee_role',
    event_name: 'employee_open_enrollment_no_auto_renewal',
    notice_triggers: [
      {
        name: 'Renewal Open Enrollment available for Employee',
        notice_template: 'notices/shop_employee_notices/8b_renewal_open_enrollment_notice_for_employee',
        notice_builder: 'ShopEmployeeNotices::OpenEnrollmentNoticeForNoRenewal',
        mpi_indicator: 'MPI_SHOP8B',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP8C',
    title: 'Your Health Plan Open Enrollment Period has Begun',
    description: 'All employees that are not currently enrolled in a plan',
    resource_name: 'employee_role',
    event_name: 'employee_open_enrollment_unenrolled',
    notice_triggers: [
      {
        name: 'Renewal Open Enrollment available for Employee',
        notice_template: 'notices/shop_employee_notices/8c_renewal_open_enrollment_notice_for_unenrolled_employee',
        notice_builder: 'ShopEmployeeNotices::OpenEnrollmentNoticeForUnenrolled',
        mpi_indicator: 'MPI_SHOP8C',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOPD015',
    title: 'Notice of Low Enrollment - Action Needed',
    description: 'Notifies all the employers who doesnt meet minimum participation requirement',
    resource_name: 'employer',
    event_name: 'low_enrollment_notice_for_employer',
    notice_triggers: [
      {
        name: 'Low Enrollment Notice',
        notice_template: 'notices/shop_employer_notices/low_enrollment_notice_for_employer',
        notice_builder: 'ShopEmployerNotices::LowEnrollmentNotice',
        mpi_indicator: 'MPI_D015',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP17',
    title: 'Open Enrollment Completed',
    description: 'All initial Employers who complete their initial Open Enrollment Period and satisfy the minimum participation and non-owner enrollmnet requirements',
    resource_name: 'employer',
    event_name: 'initial_employer_open_enrollment_completed',
    notice_triggers: [
      {
        name: 'Initial Employee Open Enrollment Successfully Completed',
        notice_template: 'notices/shop_employer_notices/17_initial_employer_open_enrollment_completed',
        notice_builder: 'ShopEmployerNotices::InitialEmployerOpenEnrollmentCompleted',
        mpi_indicator: 'MPI_SHOP17',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP13',
    title: 'Open Enrollment Reminder',
    description: 'This notices goes to all the employees in the open enrollment period',
    resource_name: 'employee_role',
    event_name: 'employee_open_enrollment_reminder',
    notice_triggers: [
      {
        name: 'Employee Open Enrollment Reminder Notice',
        notice_template: 'notices/shop_employee_notices/13_employee_open_enrollment_reminder',
        notice_builder: 'ShopEmployeeNotices::EmployeeOpenEnrollmentReminderNotice',
        mpi_indicator: 'MPI_SHOP13',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'DAE053',
    title: 'Eligible to Apply for Employer-sponsored Health Insurance',
    description: 'This notices goes to all the employees who have successfully matched their employer.',
    resource_name: 'employee_role',
    event_name: 'employee_eligibility_notice',
    notice_triggers: [
      {
        name: 'Employee Eligibility Notice',
        notice_template: 'notices/shop_employee_notices/employee_eligibility_notice',
        notice_builder: 'ShopEmployeeNotices::EmployeeEligibilityNotice',
        mpi_indicator: 'SHOP_D053',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D018',
    title: 'Group Open Enrollment Successfully Completed',
    description: 'Renewal Employee Open Enrollment Completed with minimum participation & non-owner enrollee',
    resource_name: 'employer',
    event_name: 'renewal_employer_open_enrollment_completed',
    notice_triggers: [
      {
        name: 'Renewal Employee Open Employee Completed',
        notice_template: 'notices/shop_employer_notices/renewal_employer_open_enrollment_completed',
        notice_builder: 'ShopEmployerNotices::RenewalEmployerOpenEnrollmentCompleted',
        mpi_indicator: 'SHOP_D018',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP19',
    title: 'Group Ineligible to Obtain Coverage',
    description: 'Notice goes to renewal groups who did not meet Minimum Participation Requirement or non-owner enrollee requirement after open enrollment is completed.',
    resource_name: 'employer',
    event_name: 'renewal_employer_ineligibility_notice',
    notice_triggers: [
      {
        name: 'Renewal Group Ineligible to Obtain Coverage',
        notice_template: 'notices/shop_employer_notices/19_renewal_employer_ineligibility_notice',
        notice_builder: 'ShopEmployerNotices::RenewalEmployerIneligibilityNotice',
        mpi_indicator: 'MPI_SHOP19',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP20',
    title: 'Your Invoice for Employer Sponsored Coverage is Now Available',
    description: 'When initial groups first invoice is available in their account, this notice is sent to them to instruct them on how to pay their binder payment.',
    resource_name: 'employer',
    event_name: 'initial_employer_first_invoice_available',
    notice_triggers: [
      {
        name: 'Initial Employer first invoice available in the account',
        notice_template: 'notices/shop_employer_notices/initial_employer_first_invoice_available_notice',
        notice_builder: 'ShopEmployerNotices::InitialEmployerFirstInvoiceAvailable',
        mpi_indicator: 'MPI_SHOP20',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP21',
    title: 'Monthly Invoice Available Notice',
    description: 'When groups invoice is available in their account, this notice is sent to them.',
    resource_name: 'employer',
    event_name: 'employer_invoice_available',
    notice_triggers: [
        {
          name: 'Employer monthly invoice available in the account',
          notice_template: 'notices/shop_employer_notices/employer_invoice_available_notice',
          notice_builder: 'ShopEmployerNotices::EmployerInvoiceAvailable',
          mpi_indicator: 'SHOP_D021',
          notice_trigger_element_group: {
              market_places: ['shop'],
              primary_recipients: ["employer"],
              primary_recipient_delivery_method: ["secure_message"],
              secondary_recipients: []
          }
        }
    ]
  },
  {
    hbx_id: 'SHOP26',
    title: 'First Reminder to publish Application',
    description: 'All the initial employers with draft plan years will be notified to publish their plan year 2 days prior to soft deadline of 1st.',
    resource_name: 'employer',
    event_name: 'initial_employer_first_reminder_to_publish_plan_year',
    notice_triggers: [
      {
        name: 'Initial Employer Application - Reminder to publish',
        notice_template: 'notices/shop_employer_notices/initial_employer_reminder_to_publish_plan_year',
        notice_builder: 'ShopEmployerNotices::InitialEmployerReminderToPublishPlanYear',
        mpi_indicator: 'MPI_SHOP26',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP27',
    title: 'Final Reminder to publish Application',
    description: 'All the initial employers with draft plan years will be notified to publish their plan year on 3rd of the month.',
    resource_name: 'employer',
    event_name: 'initial_employer_final_reminder_to_publish_plan_year',
    notice_triggers: [
      {
        name: 'Initial Employer Application, Deadline Extended - Reminder to publish',
        notice_template: 'notices/shop_employer_notices/initial_employer_reminder_to_publish_plan_year',
        notice_builder: 'ShopEmployerNotices::InitialEmployerReminderToPublishPlanYear',
        mpi_indicator: 'MPI_SHOP27',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP28',
    title: 'Second Reminder to publish Application',
    description: 'All the initial employers with draft plan years will be notified to publish their plan year 1 day prior to soft deadline of 1st.',
    resource_name: 'employer',
    event_name: 'initial_employer_second_reminder_to_publish_plan_year',
    notice_triggers: [
      {
        name: 'Initial Employer Application, Deadline Extended - Reminder to publish',
        notice_template: 'notices/shop_employer_notices/initial_employer_reminder_to_publish_plan_year',
        notice_builder: 'ShopEmployerNotices::InitialEmployerReminderToPublishPlanYear',
        mpi_indicator: 'MPI_SHOP28',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP29',
    title: 'Group Renewal – Final Reminder to Publish',
    description: 'Notification to renewing employers with draft plan years to publish their plan year 2 days prior to the renewal employer publishing deadline.',
    resource_name: 'employer',
    event_name: 'renewal_employer_final_reminder_to_publish_plan_year',
    notice_triggers: [
      {
        name: 'Renewal Employer reminder to publish plan year.',
        notice_template: 'notices/shop_employer_notices/renewal_employer_reminder_to_publish_plan_year',
        notice_builder: 'ShopEmployerNotices::RenewalEmployerReminderToPublishPlanyear',
        mpi_indicator: 'MPI_SHOP29',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D041',
    title: 'Employee Terminating coverage',
    description: 'Employee Terminating coverage after QLE',
    resource_name: 'employer',
    event_name: 'notify_employer_when_employee_terminate_coverage',
    notice_triggers: [
      {
        name: 'Notice to employer when employee terminates coverage',
        notice_template: 'notices/shop_employer_notices/employee_terminating_coverage',
        notice_builder: 'ShopEmployerNotices::EmployeeTerminatingCoverage',
        mpi_indicator: 'SHOP_D041',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP30',
    title: 'Group Renewal – Second Reminder to Publish',
    description: 'Notification to renewing employers with draft plan years to publish their plan year 1 day prior to the renewal employer soft deadline.',
    resource_name: 'employer',
    event_name: 'renewal_employer_second_reminder_to_publish_plan_year',
    notice_triggers: [
      {
        name: 'Renewal Employer reminder to publish plan year.',
        notice_template: 'notices/shop_employer_notices/renewal_employer_reminder_to_publish_plan_year',
        notice_builder: 'ShopEmployerNotices::RenewalEmployerReminderToPublishPlanyear',
        mpi_indicator: 'MPI_SHOP30',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP31',
    title: 'Group Renewal – First Reminder to Publish',
    description: 'Notification to renewing employers with draft plan years to publish their plan year 2 days prior to the renewal employer soft deadline.',
    resource_name: 'employer',
    event_name: 'renewal_employer_first_reminder_to_publish_plan_year',
    notice_triggers: [
      {
        name: 'Renewal Employer reminder to publish plan year.',
        notice_template: 'notices/shop_employer_notices/renewal_employer_reminder_to_publish_plan_year',
        notice_builder: 'ShopEmployerNotices::RenewalEmployerReminderToPublishPlanyear',
        mpi_indicator: 'MPI_SHOP31',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D020',
    title: 'Group Ineligible to Obtain Coverage',
    description: 'Initial employee Open Enrollment Completed (Did Not Meet Minimum Participation Requirement or non-owner enrollee requirement)',
    resource_name: 'employer',
    event_name: 'initial_employer_ineligibility_notice',
    notice_triggers: [
      {
        name: 'Initial Employer ineligible to obtain coverage.',
        notice_template: 'notices/shop_employer_notices/initial_employer_ineligibility_notice',
        notice_builder: 'ShopEmployerNotices::InitialEmployerIneligibilityNotice',
        mpi_indicator: 'SHOP_D020',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D005',
    title: 'Employer Annual Renewal - Denial of Eligibility',
    description: 'denial of eligibility for employer as failed resindency',
    resource_name: 'employer',
    event_name: 'employer_renewal_eligibility_denial_notice',
    notice_triggers: [
      {
        name: 'Employer Annual Renewal - Denial of Eligibility',
        notice_template: 'notices/shop_employer_notices/employer_renewal_eligibility_denial_notice',
        notice_builder: 'ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice',
        mpi_indicator: 'SHOP_D005',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
      hbx_id: 'SHOP_D052',
      title: 'Confirmation - Broker Fired',
      description: 'Broker gets terminated after employer selects change broker',
      resource_name: 'employer',
      event_name: 'employer_broker_fired',
      notice_triggers: [
          {
              name: 'YOU REMOVED YOUR BROKER ON DC HEALTH LINK',
              notice_template: 'notices/shop_employer_notices/employer_broker_fired_notice',
              notice_builder: 'ShopEmployerNotices::EmployerBrokerFiredNotice',
              mpi_indicator: 'SHOP_D052',
              notice_trigger_element_group: {
                  market_places: ['shop'],
                  primary_recipients: ["employer"],
                  primary_recipient_delivery_method: ["secure_message"],
                  secondary_recipients: []
              }
          }
      ]
  },
  {
    hbx_id: 'SHOP35',
    title: 'Special Enrollment Period Denial',
    description: 'EE SEP Requested by Employee outside of allowable time frame',
    resource_name: 'employee_role',
    event_name: 'sep_request_denial_notice',
    notice_triggers: [
      {
        name: 'Denial of SEP Requested by EE outside of allowable time frame',
        notice_template: 'notices/shop_employee_notices/sep_request_denial_notice',
        notice_builder: 'ShopEmployeeNotices::SepRequestDenialNotice',
        mpi_indicator: 'MPI_SHOP35',
                notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP51',
    title: 'You have been removed as a broker',
    description: "When a Broker is fired by an employer, the broker receives this notification letting them know they are no longer the broker for the client.",
    resource_name: 'broker_role',
    event_name: 'broker_fired_confirmation_to_broker',
    notice_triggers: [
      {
        name: 'Broker Fired',
        notice_template: 'notices/shop_broker_notices/broker_fired_notice',
        notice_builder: 'ShopBrokerNotices::BrokerFiredNotice',
        mpi_indicator: 'SHOP_D051',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["broker"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP10047',
    title: 'Termination of Employer’s Health Coverage Offered through DC Health Link',
    description: 'Notification to employees regarding their Employer’s ineligibility.',
    resource_name: 'employee_role',
    event_name: 'notify_employee_of_initial_employer_ineligibility',
    notice_triggers: [
      {
        name: 'Notification to employees regarding their Employer’s ineligibility.',
        notice_template: 'notices/shop_employee_notices/notification_to_employee_due_to_initial_employer_ineligibility',
        notice_builder: 'ShopEmployeeNotices::NotifyEmployeeOfInitialEmployerIneligibility',
        mpi_indicator: 'MPI_SHOP10047',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D049',
    title: 'Confirmation - Broker Hired',
    description: 'Confirmation of Broker Hired Sent to Employer',
    resource_name: 'employer',
    event_name: 'broker_hired_confirmation_notice',
    notice_triggers: [
      {
        name: 'Boker Hired Confirmation',
        notice_template: 'notices/shop_employer_notices/broker_hired_confirmation_notice',
        notice_builder: 'ShopEmployerNotices::BrokerHiredConfirmationNotice',
        mpi_indicator: 'SHOP_D049',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D046',
    title: 'Employee has made a change to their employer-sponsored coverage selection',
    description: 'Employee mid year plan change when an eligiblity determination is reached',
    resource_name: 'employer',
    event_name: 'ee_mid_year_plan_change_congressional_notice',
    notice_triggers: [
      {
        name: 'Employee Mid-Year Plan change Congressional',
        notice_template: 'notices/shop_employer_notices/ee_mid_year_plan_change_notice_congressional',
        notice_builder: 'ShopEmployerNotices::EeMidYearPlanChangeNotice',
        mpi_indicator: 'SHOP_D046',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D045',
    title: 'Employee has made a change to their employer-sponsored coverage selection',
    description: 'Employee mid year plan change when an eligiblity determination is reached',
    resource_name: 'employer',
    event_name: 'ee_mid_year_plan_change_non_congressional_notice',
    notice_triggers: [
      {
        name: 'Employee Mid-Year Plan change Non-Congressional',
        notice_template: 'notices/shop_employer_notices/employee_mid_year_plan_change_non_congressional',
        notice_builder: 'ShopEmployerNotices::EeMidYearPlanChangeNotice',
        mpi_indicator: 'SHOP_D045',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D001',
    title: 'Welcome to DC Health Link',
    description: 'ER creates an account in DC Health',
    resource_name: 'employer',
    event_name: 'employer_account_creation_notice',
    notice_triggers: [
      {
        name: 'Welcome Notice sent to Employer',
        notice_template: 'notices/shop_employer_notices/employer_account_creation_notice',
        notice_builder: 'ShopEmployerNotices::EmployerAccountCreationNotice',
        mpi_indicator: 'SHOP_D001',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP10066',
    title: 'Termination of Employer’s Health Coverage Offered through DC Health Link',
    description: 'Notify Employees of their Employer Termination from SHOP due to ineligibility',
    resource_name: 'employee_role',
    event_name: 'notify_employee_of_renewing_employer_ineligibility',
    notice_triggers: [
      {
        name: 'Notify Employees of their employer termination due to ineligibility',
        notice_template: 'notices/shop_employee_notices/notification_to_employee_due_to_renewal_employer_ineligibility',
        notice_builder: 'ShopEmployeeNotices::NotifyEmployeeDueToRenewalEmployerIneligibility',
        mpi_indicator: 'MPI_SHOP10066',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'D048',
    title: 'You have been hired as a broker',
    description: "When a broker is hired to a group, a notice is sent to the broker's broker mail inbox alerting them of the hire.",
    resource_name: 'broker_role',
    event_name: 'broker_hired',
    notice_triggers: [
      {
        name: 'Broker Hired',
        notice_template: 'notices/shop_broker_notices/broker_hired_notice',
        notice_builder: 'ShopBrokerNotices::BrokerHiredNotice',
        mpi_indicator: 'SHOP_D048',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["broker"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'D047',
    title: 'You have been Hired as their Broker Agency',
    description: "When a Broker Agency is hired by an employer, they receive this notification letting them know they have a new client assigned to them.",
    resource_name: 'broker_role',
    event_name: 'broker_agency_hired',
    notice_triggers: [
      {
        name: 'Broker Agency Hired',
        notice_template: 'notices/shop_broker_notices/broker_agency_hired_notice',
        notice_builder: 'ShopBrokerNotices::BrokerAgencyHiredNotice',
        mpi_indicator: 'SHOP_D047',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["broker"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D074',
    title: 'Employee Enrollment Confirmation',
    description: 'Notification to employees regarding plan purchase during Open Enrollment or an SEP.',
    resource_name: 'employee_role',
    event_name: 'ee_plan_selection_confirmation_sep_new_hire',
    notice_triggers: [
      {
        name: 'Notification to employees regarding plan purchase during Open Enrollment or an SEP.',
        notice_template: 'notices/shop_employee_notices/ee_plan_selection_confirmation_sep_new_hire',
        notice_builder: 'ShopEmployeeNotices::EePlanConfirmationSepNewHire',
        mpi_indicator: 'SHOP_D074',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },

  {
    hbx_id: 'SHOP_D034',
    title: 'Special Enrollment Period Approval',
    description: 'SEP request by Employee accepted when an eligiblity determination is reached',
    resource_name: 'employee_role',
    event_name: 'ee_sep_request_accepted_notice',
    notice_triggers: [
      {
        name: 'EE SEP Requested Accepted',
        notice_template: 'notices/shop_employee_notices/ee_sep_request_accepted_notice',
        notice_builder: 'ShopEmployeeNotices::EeSepRequestAcceptedNotice',
        mpi_indicator: 'SHOP_D034',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  
  {
    hbx_id: 'SHOP_DAG043',
    title: 'Confirmation of Termination of Employer-Sponsored Health Coverage',
    description: 'Group termination confirmation for advance request',
    resource_name: 'employer',
    event_name: 'group_advance_termination_confirmation',
    notice_triggers: [
      {
        name: 'Confirmation notice to employer after group termination',
        notice_template: 'notices/shop_employer_notices/group_advance_termination_confirmation',
        notice_builder: 'ShopEmployerNotices::GroupAdvanceTerminationConfirmation',
        mpi_indicator: 'MPI_D043',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
           primary_recipient_delivery_method: ["secure_message"],
           secondary_recipients: []
         }
       }
     ]
   },
   {
    hbx_id: 'SHOP_D091',
    title: 'Dental Carrier Exit from DC Health Link’s Small Business Marketplace',
    description: 'Notify Employers of their Dental Carriers are Exiting',
    resource_name: 'employer',
    event_name: 'employer_renewal_dental_carriers_exiting_notice',
    notice_triggers: [
      {
        name: 'Notice to Renewal ERs Dental Carriers are Exiting SHOP in 2018',
        notice_template: 'notices/shop_employer_notices/employer_renewal_dental_carriers_exiting_notice',
        notice_builder: 'ShopEmployerNotices::EmployerRenewalDentalCarriersExitingNotice',
        mpi_indicator: 'SHOP_D091',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employer"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D092',
    title: 'Dental Carrier Exit from DC Health Link’s Small Business Marketplace',
    description: 'Notify Renewal Employees of dental plan carriers are exiting SHOP market',
    resource_name: 'employee_role',
    event_name: 'notify_renewal_employees_dental_carriers_exiting_shop',
    notice_triggers: [
      {
        name: 'Renewal EEs Dental Carriers are Exiting SHOP market notice',
        notice_template: 'notices/shop_employee_notices/notify_renewal_employees_dental_carriers_exiting_shop',
        notice_builder: 'ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop',
        mpi_indicator: 'SHOP_D092',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D093',
    title: 'Dental Carrier Exit from DC Health Link’s Small Business Marketplace',
    description: 'Notify Renewal Employees of dental plan carriers are exiting SHOP market - Excludes 1/1/2018 renewal EEs',
    resource_name: 'employee_role',
    event_name: 'dental_carriers_exiting_shop_notice_to_ee',
    notice_triggers: [
      {
        name: 'Renewal EEs Dental Carriers are Exiting SHOP market notice - Excludes 1/1/2018 renewal EEs',
        notice_template: 'notices/shop_employee_notices/notify_renewal_employees_dental_carriers_exiting_shop',
        notice_builder: 'ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop',
        mpi_indicator: 'SHOP_D093',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
  {
    hbx_id: 'SHOP_D042',
    title: 'Confirmation of Election To Terminate Coverage',
    description: 'Employee Terminating coverage after QLE',
    resource_name: 'employee_role',
    event_name: 'notify_employee_confirming_coverage_termination',
    notice_triggers: [
      {
        name: 'Notice to employee when employee terminates coverage',
        notice_template: 'notices/shop_employee_notices/employee_terminating_coverage_confirmation',
        notice_builder: 'ShopEmployeeNotices::EmployeeTerminatingCoverageConfirmation',
        mpi_indicator: 'SHOP_D042',
        notice_trigger_element_group: {
          market_places: ['shop'],
          primary_recipients: ["employee"],
          primary_recipient_delivery_method: ["secure_message"],
          secondary_recipients: []
        }
      }
    ]
  },
]

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
      hbx_id: 'IVL_DCH',
      title: 'YOUR INSURANCE THROUGH COVER ALL DC HAS CHANGED TO DC HEALTH LINK',
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
  },

]

shop_notice_triggers.each do |trigger_params|
  ApplicationEventKind.create(trigger_params)
end

ivl_notice_triggers.each do |trigger_params|
  ApplicationEventKind.create(trigger_params)
end