---
title: "Employees"
date: 2020-12-11T12:12:25-05:00
draft: false
---

In Enroll terminology, Employees are those employed by the various Employers who utilize Enroll to allow their employees to select coverage.

## Employees UI Walkthrough and Technical Explanation

Employees are first entered into Enroll as "Census Employees" by Employers/Admins on the Employer Census Details page. The steps to reach this would be:

1. After an Employer is approved, visit employer's page.
2. Click the "Employees" tab on the left side of the page.
3. Click "Add New Employee" and fill out info.

When an Employee registers an account and enters their information, their name/SSN/DOB will match employee’s date of birth and SSN to the information provided on the employer’s roster. Once matched to the roster, the employee is then able to shop for a plan if the employee is in an eligible enrollment period (i.e. open enrollment period or special enrollment period).

*Relevant Cucumbers*
[Census Employee Details Page](https://github.com/dchbx/enroll/blob/master/features/employers/census_details_page.feature)

After an Employee is matched, the Person record associated with that individual will have an Employee role created with it, and that employee role will also be associated with the Census Employee. The Census Employee record will also contain references of the hiring status of that employee. Please note that a Person record can have *multiple* employee roles (logically, as someone might have multiple jobs offering benefits).

_Dev Notes_: The matching between employees/census employees takes place in the `match` action of the Employee Roles Controller. Most of the logic for matching takes place in the Employee Candidate class.

*Relevant Files*
[Census Employee Model](https://github.com/dchbx/enroll/blob/master/app/models/census_employee.rb)
[Employee Role](https://github.com/dchbx/enroll/blob/master/app/models/employee_role.rb)
[Person](https://github.com/dchbx/enroll/blob/master/app/models/person.rb)
[Employee Roles Controller]()
[Employee Candidate](https://github.com/dchbx/enroll/blob/master/app/models/forms/employee_candidate.rb)

# Plan Shopping

Employees have a streamlined plan shopping experience. Eligibility is auto determined by matching the employee’s date of birth and SSN to the information provided on the employer’s roster. Once matched to the roster, the employee is then able to shop for a plan if the employee is in an eligible enrollment period (i.e. open enrollment period or special enrollment period).

In employee plan shopping, the employee can see all available plans with different levels of plan details and multiple filter/sorting options (i.e. by premium, by deductible, by carrier, by plan type, by metal level). Employees can can select to look at full plan details for any given plan. All plan information that is included in the SERFF templates is available for display in the plan shopping experience.

# Other Decision Support
Multiple levels of plan information available in plan shopping experience – high level basic information, overview of “top 10” benefits, SBCs, and very detailed benefit information for all elements from CCIIO templates.

Detailed plan shopping side-by-side comparison of up to every data element in the CCIIO templates filed by the carriers.

We are contiuously reviewing the plan shopping experience with our team of user interface experts to allow for informed plan selections and facilitate improved health insurance literacy of our customer base. For example, we recently completed moderated user testing of our individual shopping experience. Improvements based on moderated user testing for plan comparison will also be made to SHOP shopping. We are also planning moderated user testing for employer and employee customers in SHOP.
