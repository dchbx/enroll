---
title: "HBX Enrollments"
date: 2020-12-14T12:12:25-05:00
draft: false
---

The backbone of the Enroll application, the HBX Enrollment class each individual health or dental policy.

# Model Overview

The HBX Enrollment Model contains critical information about the enrollment, such as:

- Kind: individual employer_sponsored employer_sponsored_cobra coverall unassisted_qhp insurance_assisted_qhp streamlined_medicaid emergency_medicaid hcr_chip
- Enrollment Kind: Open Enrollment, Special Enrollment
- Coverage Kind: Health/Dental
- AASM State: Coverage Selected, Inactive, etc.
- Waiver Reason
- Plan ID

_Dev Note_: While HBX Enrollments contain a family ID and can be referenced as many belonging to _Family_ (I.E. family.hbx_enrollments), HBX Enrollment is a *top level* model. They'll commonly be queried with thee *hbx_id* attribute.

Check out more directly on the [HBX Enrollment](https://github.com/dchbx/enroll/blob/master/app/models/hbx_enrollment.rb) file.

# Display of HBX Enrollment on Website UI

During the plan shopping process, an HBX Enrollment record will be created attached to that person's family. Also note, if the user *exits* the plan shopping process without making a purchase, the HBX Enrollment will revert to an AASM state of _shopping_ and will not have a _plan_ attached to it.

After shopping and successfully purchasing a plan, the information for HBX Enrollment is primarily displayed on the "enrollment tile", which can be accessed through the *Families Home Page* (for the view of the employee/individual consumer) and *Census Detail Page* (for the Employer).

_Dev Note_:
The code to to display the enrollment information tile can be found in the [enrollment.html.erb partial](https://github.com/dchbx/enroll/blob/master/app/views/insured/families/_enrollment.html.erb). Careful attention should be paid when changing this file.

*Relevant Cucumbers*:
[Census Employee Details Page](https://github.com/dchbx/enroll/blob/master/features/employers/census_details_page.feature)
<br />
[Employee Plan Shopping](https://github.com/dchbx/enroll/blob/master/features/employee/employee_plan_shopping.feature)
<br />
[Individual Plan Shopping](https://github.com/dchbx/enroll/blob/master/features/group_selection/ivl_plan_shopping.feature)

# IVL Market Termination Self-Service

Todo
