---
title: "Special Enrollment Periods/Qualifying Life Event Kinds"
date: 2020-11-18T12:12:25-05:00
draft: true
---

The Enroll Application offers both employee self-attested, and caseworker-managed, Qualifying Life Events and resulting Special Enrollment Periods. 

## Special Enrollment Periods (SEP)/Qualifying Life Event (QLE) Kinds

QLE types are fully configurable, with attributes including: title, tool tip, event label, relative order of appearance in QLE list, EDI code, effective on date kinds, SEP time period preceding QLE, SEP time period following QLE and self-attested flag. For example, following is a QLE definition for birth of child:

- title: “Had a baby”,
- tool_tip: “Household adds a member due to marriage, birth, adoption, placement for adoption, or placement in foster care”,
- edi_code: “02-BIRTH”,
- effective_on_kinds: [“date_of_event”],
- pre_event_sep_in_days: 0,
- post_event_sep_in_days: 30,
- is_self_attested: true,
- ordinal_position: 25,
- event_kind_label: ‘Date of birth’

Self-attested QLE’s are available to Employees, and are governed by the configured attributes. The User Interface guides the employee the SEP creation process step-by-step, presenting appropriate options based on the selected QLE type.

Following successful creation, the family is eligible to make enrollment changes for the duration of the SEP.

All self-attested and non-self-attested SEPs will be available to caseworkers through the administrator portal to grant SEPs to employees. This is currently in pre-prod. Administration SEP types may be configured to provide caseworkers with flexibility to set non-standard start and end dates, and offer multiple effective date options to the employee.

Viewing/selecting QLE's can be achieved through the following steps:

1. Login as an employee/Click an employee name from the Families index as an admin
2. From the families home page, look to the right of the page for a box labeled "Have life changes?"
3. The "Have life changes?" box will contain the list of Qualifying Life Event Kinds.

*Relevant Cucumbers*
[Individual SEP Signup](https://github.com/dchbx/enroll/blob/master/features/insured/individual_sep_signup.feature)

_Developer Notes:
- Check `group_selection_controller.rb` to view how the SpecialEnrollmentPeriod model interacts with the `family` and `HBXEnrollment` models.
- Check the method `init_qualifying_life_events` in the `families_controller.rb` file to view the initializing process for QLE Kinds_


# Create/Manage Qualifying Life Event Kinds (QLEK)

Admin users have the capability of managing/creating QLE Kinds via the website UI with the following steps:

1. Login as an HBX Admin and click "I'm an Admin."
2. Click the Admin dropdown and click Manage SEP's

When creating or modifying a new SEP, users must be sure to *publish* the SEP (available as a button on the manage SEP form) after creating one. This is to comply with the specific rules regarding valid QUalifying Life Event Kinds.

*Relevant Cucumbers*
[Manage SEPs](https://github.com/dchbx/enroll/tree/master/features/hbx_admin/manage_sep_types) - all files ending with .feature


# Adding SEPs to Families as Admin

Admin users can also manually create a special enrollment period for a family with the following steps:

1. Login as an HBX Admin and click "I'm an Admin."
2. Click the Families dropdown and go to the Families Index
3. Next to the target family, click the "Actions" dropdown.
4. Select a QLE Kind for the SEP reason and enter comments.

*Relevant Cucumbers*
[Add SEP Read and Write](https://github.com/dchbx/enroll/blob/master/features/admin/add_sep_read_and_write.feature.wip)

_Developer Notes: Checkout the dropdown actions in family_data_table.rb_

