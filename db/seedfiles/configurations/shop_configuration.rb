SHOP_CONFIGURATIONS = {
   "valid_employer_attestation_documents_url": 
    { default: 'https://www.mahealthconnector.org/business/business-resource-center/employer-verification-checklist'},
   "small_market_employee_count_maximum": {default: 50},
   "employer_contribution_percent_minimum": {default: 50},
   "employer_family_contribution_percent_minimum": {default: 33},
   "employee_participation_ratio_minimum": {default: "<%= 3 / 4.0 %>"},
   "non_owner_participation_count_minimum": {default: 1},
   "binder_payment_due_on": {default: 23},
   "small_market_active_employee_limit": {default: 200},
   "new_employee_paper_application": {default: true},
   "census_employees_template_file": {default: 'Health Connector - Employee Census Template'},
   "coverage_start_period": {default: "2 months"},
   "earliest_enroll_prior_to_effective_on.days": {default: -30},
   "latest_enroll_after_effective_on.days": {default: 30},
   "latest_enroll_after_employee_roster_correction_on.days": {default: 30},
   "retroactive_coverage_termination_maximum.days": {default: -60}
}