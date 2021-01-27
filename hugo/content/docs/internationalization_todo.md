---
title: "Internationalization Todo"
date: 2021-01-13T12:12:25-05:00
draft: true
---

The following file lists represents file which require some degree of internationalization in Enroll as of 1/13/2021. 

# Main App

app/views/broker_agencies/applicants/_bank_information.html.erb
app/views/broker_agencies/applicants/index.js.erb

app/views/broker_agencies/broker_roles/_existing_broker_agency_form.html.erb
app/views/broker_agencies/broker_roles/_new_broker_agency_form.html.
app/views/broker_agencies/broker_roles/confirmation.html.erb

app/views/broker_agencies/profiles/_families_table_for_broker.html.erb
app/views/broker_agencies/profiles/_form.html.erb
app/views/broker_agencies/profiles/_menu.html.erb
app/views/broker_agencies/profiles/_office_locations.html.erb.html.erb
app/views/broker_agencies/profiles/_show.html.erb.html.erb
app/views/broker_agencies/profiles/_staff_table.html.erb.html.erb

app/views/broker_agencies/quotes/_staff_table.html.erb.html.erb
app/views/broker_agencies/quotes/_edit_form.html.erb.html.erb
app/views/broker_agencies/quotes/_employee_cost_breakdown_for_dental_plans.html.erb
app/views/broker_agencies/quotes/_employee_cost_breakdown_for_health_plans.html.erb
app/views/broker_agencies/quotes/_health_cost_comparison.html.erb
app/views/broker_agencies/quotes/_plan_comparison_export.html.erb
app/views/broker_agencies/quotes/_publish.html.erb
app/views/broker_agencies/quotes/_publish.edf.erb
app/views/broker_agencies/quotes/_quote_household.html.erb
app/views/broker_agencies/quotes/_quote_members.html.erb
app/views/broker_agencies/quotes/_select_plans.html.erb
app/views/broker_agencies/quotes/_upload_employee_modal.html.erb
app/views/broker_agencies/quotes/new.html.erb
app/views/broker_agencies/quotes/new.html.erb
app/views/broker_agencies/quotes/show.html.erb


app/views/broker_agencies/quotes/panels/_dental.html.erb
app/views/broker_agencies/quotes/panels/_my_features.html.erb
app/views/broker_agencies/quotes/panels/_my_plans.html.erb

app/views/datatables/_cancel_enrollment.html.erb
app/views/datatables/_cancel_enrollment_result.html.erb
app/views/datatables/_terminate_enrollment.html.erb
app/views/datatables/_terminate_enrollment_result.html.erb

app/views/devise/confirmations/new.html.erb
app/views/devise/mailer/reset_password_instructions.html.erb
app/views/devise/mailer/unlock_instructions.html.erb
app/views/devise/passwords/_edit.html.erb
app/views/devise/mailer/unlock_instructions.html.erb
app/views/devise/passwords/create.js.erb
app/views/devise/mailer/unlock_instructions.html.erb
app/views/devise/passwords/edit.html.erb
app/views/devise/mailer/unlock_instructions.html.erb
app/views/devise/passwords/new.html.slim

app/views/devise/registrations/new.html.slim

app/views/devise/sessions/_session_expiration_warning.html.erb
app/views/devise/sessions/ssession_expiration_warning.js.erb

app/views/shared/_sign_in.html.erb

app/views/devise/unlocks/new.html.erb

app/views/documents/_new.erb

app/views/employees/_form.html.erb

app/views/employers/census_employees/_address_fields.html.erb
app/views/employers/census_employees/_cobra_fields.html.erb
app/views/employers/census_employees/dependent_fields.html.erb
app/views/employers/census_employees/_details.html.erb
app/views/employers/census_employees/_email_fields.html.erb
app/views/employers/census_employees/_enrollment_details.html.erb
app/views/employers/census_employees/_errors_if_any.html.erb
app/views/employers/census_employees/_form.html.erb
app/views/employers/census_employees/_initiate_cobra.html.erb
app/views/employers/census_employees/_member_fields.html.erb
app/views/employers/census_employees/_rehire_employee.html.erb
app/views/employers/census_employees/_sidebar.html.erb
app/views/employers/census_employees/_terminate_employee.html.erb
app/views/employers/census_employees/show.html.erb

app/views/employer/_broker_info_fields.html.erb
app/views/employer/_coverage_fields.html.erb
app/views/employer/_credentials_fields.html.erb
app/views/employer/_eligibility_rules_fields.html.erb
app/views/employer/_emp_contact_fields.html.erb
app/views/employer/_emp_contributions_fields.html.erb
app/views/employer/_form.html.erb
app/views/employer/_name_fields.html.erb
app/views/employer/_plan_selection_fields.html.erb
app/views/employer/_sidebar.html.erb
app/views/employer/_tax_fields.html.erb
app/views/employer/_welcome_msg.html.erb
app/views/employer/index.html.erb
app/views/employer/show.html.erb

app/views/employer_attestations/_edit.html.erb
app/views/employer_attestations/_new.html.erb
app/views/employer_attestations/_verify_attestation.html.erb
app/views/employer_attestations/_verify_attestation.js.erb

app/views/employer_profiles/_broker_info_fields.html.erb
app/views/employer_profiles/_coverage_fields.html.erb
app/views/employer_profiles/_credentials_fields.html.erb
app/views/employer_profiles/_download_new_template.html.erb
app/views/employer_profiles/_eligibility_rules_fields.html.erb
app/views/employer_profiles/_emp_contact_fields.html.erb
app/views/employer_profiles/_emp_contributions_fields.html.erb
app/views/employer_profiles/_employer_info_form.html.erb
app/views/employer_profiles/_employer_invoices_table.html.erb
app/views/employer_profiles/_employer_menu.html.erb
app/views/employer_profiles/_enrollment_report_widget.html.erb
app/views/employer_profiles/_form.html.erb
app/views/employer_profiles/_index.html.erb
app/views/employer_profiles/_no_match.html.haml
app/views/employer_profiles/_open_enrollment_ends_panel.html.erb
app/views/employer_profiles/_plan_selection_fields.html.erb
app/views/employer_profiles/_primary_nav.html.erb
app/views/employer_profiles/_search_fields.html.erb
app/views/employer_profiles/_sidebar.html.erb
app/views/employer_profiles/_tax_fields.html.erb
app/views/employer_profiles/bulk_employee_upload_form.html.erb
app/views/employer_profiles/index.html.erb


app/views/employer_profiles/my_account/_benefits.html.erb
app/views/employer_profiles/my_account/_billing.html.erb
app/views/employer_profiles/my_account/_broker_agency.html.erb
app/views/employer_profiles/my_account/_census_employees.html.erb
app/views/employer_profiles/my_account/_documents.html.erb
app/views/employer_profiles/my_account/_employees_by_status.html.erb
app/views/employer_profiles/my_account/_employer_welcome.html.slim
app/views/employer_profiles/my_account/_enrollment_progress_bar.html.erb
app/views/employer_profiles/my_account/_families.html.erb
app/views/employer_profiles/my_account/_home_tab.html.slim
app/views/employer_profiles/my_account/_profile_tab.html.erb

app/views/employer_profiles/show.html.erb
app/views/employer_profiles/show_pending.html.erb
app/views/employer_profiles/show_profile.html.erb

app/views/people/_no_match.html.haml
app/views/people/_person_fields.html.erb
app/views/people/_person_info_form.html.erb
app/views/people/_search_fields.html.erb

app/views/employers/plan_years/_benefit_group.html.erb
app/views/employers/plan_years/_benefit_group_summary.html.erb
app/views/employers/plan_years/_dental_reference_plans_options_modal.html.erb
app/views/employers/plan_years/_employee_costs_modal.html.erb
app/views/employers/plan_years/_form.html.erb
app/views/employers/plan_years/_plan_options.html.erb
app/views/employers/plan_years/_recommend_dates.html.erb
app/views/employers/plan_years/_reference_plan_info.html.erb
app/views/employers/plan_years/_reference_plan_summary_modal.html.erb
app/views/employers/plan_years/_revert_modal.html.erb


app/views/employers/plan_years/plan_selection/_offered_plan.html.erb
app/views/employers/plan_years/plan_selection_plan_details.html.erb
app/views/employers/plan_years/plan_selection_single_carriers.html.erb

app/views/employers/premium_statements/_benefit_line_item_detail.html.erb
app/views/employers/premium_statements/_employee_line_item.html.erb
app/views/employers/premium_statements/_show.html.erb
app/views/employers/premium_statements/how.html.erb

app/views/exchanges/agents/_consumer_application_links.html.erb
app/views/exchanges/agents/_employee_application_links.html.erb
app/views/exchanges/agents/_individual_message.html.erb
app/views/exchanges/agents/_message.html.erb
app/views/exchanges/agents/_message_list.html.erb
app/views/exchanges/agents/_primary_nav.html.erb
app/views/exchanges/agents/home.html.erb

# Benefit Markets

# Benefit Sponsors

# Financial Assistance

# Notifier

# Sponsored Benefits

# Transport Gateway

# Transport Profiles

# UI Helpers