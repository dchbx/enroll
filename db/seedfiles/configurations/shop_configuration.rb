SHOP_CONFIGURATIONS = {
    "shop.valid_employer_attestation_documents_url": {
        is_required: true,
        description: 'this is the url for employer attestation',
        default: 'https://www.mahealthconnector.org/business/business-resource-center/employer-verification-checklist'
        },
    "shop.small_market_employee_count_maximum": {
        is_required: true,
        default: 50
        },
    "shop.earliest_enroll_prior_to_effective_on.days": {
        is_required: true,
        default: -30
    },
    "employee_participation_ratio_minimum": {
        is_required: true,
        default: "<%= 3 / 4.0 %>"
    },
    "shop.rating_areas": {
       is_required: true,
       default: %w(R-MA001 R-MA002 R-MA003 R-MA004 R-MA005)
    },
    "shop.congress.open_enrollment_period.begin": {
       is_required: true,
       default: "<%= Date.new(2019, 11, 13) %>"
    }
}
    # "shop.employer_contribution_percent_minimum": 50,
    # "shop.employer_family_contribution_percent_minimum": 33,
    # # "employee_participation_ratio_minimum": <%= 3 / 4.0 %>,
    # "shop.non_owner_participation_count_minimum": 1,
    # "shop.binder_payment_due_on": 23,
    # "shop.small_market_active_employee_limit": 200,
    # "shop.new_employee_paper_application": true,
    # "shop.census_employees_template_file": 'Health Connector - Employee Census Template',
    # "shop.coverage_start_period": "2 months",
    # "shop.earliest_enroll_prior_to_effective_on.days": -30,
    # "shop.latest_enroll_after_effective_on.days": 30,
    # "shop.latest_enroll_after_employee_roster_correction_on.days": 30,
    # "shop.retroactive_coverage_termination_maximum.days": -60,
    # "shop.initial_application.publish_due_day_of_month": 15,
    # "shop.initial_application.advertised_deadline_of_month": 10,
    # "shop.initial_application.earliest_start_prior_to_effective_on.months": -2,
    # "shop.initial_application.earliest_start_prior_to_effective_on.day_of_month": 0,
    # "shop.initial_application.appeal_period_after_application_denial.days": 30,
    # "shop.initial_application.ineligible_period_after_application_denial.days": 90,
    # "shop.initial_application.quiet_period.month_offset": 0,
    # "shop.initial_application.quiet_period.mday": 8,
    # "shop.renewal_application.earliest_start_prior_to_effective_on.months": -2,
    # "shop.renewal_application.earliest_start_prior_to_effective_on.day_of_month": 0,
    # "shop.renewal_application.monthly_open_enrollment_end_on": 20,
    # "shop.renewal_application.publish_due_day_of_month": 15,
    # "shop.renewal_application.application_submission_soft_deadline": 10,
    # "shop.renewal_application.force_publish_day_of_month": 16,
    # "shop.renewal_application.open_enrollment.minimum_length.days": 5,
    # "shop.renewal_application.quiet_period.month_offset": -1,
    # "shop.renewal_application.quiet_period.mday": 26