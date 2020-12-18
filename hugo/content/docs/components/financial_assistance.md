---
title: "Financial Assistance Engine"
section: "Components'"
date: 2020-11-18T12:11:47-05:00
draft: false
---

Financial Assistance (FA) is a [Rails Engine](https://guides.rubyonrails.org/engines.html) found in the components/ folder of Enroll. FA is designed to provide an application intake process for Medicaid and APTC through the Assisted/Consumer Family portal accessed through the root page of Enroll. Like all engines, the Financial Assistance engine can be toggled through the EnrollRegistry.

## Basic User Interface Walkthrough and Models Overview

# Application

Application is the top level model of the FA engine, referencing the family ID from the root Enroll app. The application model records data such as the application kind ("user and/or family", "call center rep or case worker", "authorized representative"), source kind ("paper", "source", in-person"]), motivation kind ("insurance affordability"), etc. Assuming EnrollRegistry has the FA engine enabled, reaching the application flow can be achieved through the following steps:

1. Visit the root URL of Enroll
2. Click "Assisted/Consumer Family Portal"
3. You will be brought to a page to fill out information for the person, and go through a workflow which contains all questions related to the application.

# Applicants

The applicant model contains fields related to demographic and other information to determine the validity of the applicant such as tax filer status, immigration status, student kind, tobacco use, etc. The user will fill out all of these fields for each applicant during the FA application process. The application model "belongs" to Applications, and Applications can "have many" applicants.

# Benefits

The benefits model concerns the types of benefits for which the applicant is eligible, which are:
- Acf refugee medical assistance
- Americorps health benefits
- Child health insurance plan
- Medicaid
- Medicare
- Medicare advantage
- Medicare part b
- Private individual and family coverage
- State supplementary payment
- Tricare
- Veterans benefits
- Naf health benefit program
- Health care for peace corp volunteers
- Department of defense non appropriated health benefits
- Cobra
- Employer sponsored insurance
- Self funded student health coverage
- Foreign government health coverage
- Private health insurance plan
- Coverage obtained through another exchange
- Coverage under the state health benefits risk pool
- Veterans administration health benefits
- Peace corps health benefits

Benefits "belong to" Applicants, who can "have many" Benefits.

# Incomes

Incomes "belong to" Applicants, who can "have many" Incomes. Income types include alimony, pension or retirement benefits, etc.

# Deductions

Deductions "belong to" Applicants, who can have many Deductions. Deduction types include alimony paid, student loan interest, etc.

*Relevant Cucumbers*

[Financial Assistance Related Cucumbers](https://github.com/dchbx/enroll/tree/master/features/financial_assistance) - includes family relationships page, help paying coverage, household info, etc. See all files ending with .feature