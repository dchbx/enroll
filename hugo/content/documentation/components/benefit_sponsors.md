---
title: "Benefit Sponsors Engine"
date: 2020-12-10T12:11:29-05:00
draft: true
---

"Benefit Sponsors" is a [Rails Engine](https://guides.rubyonrails.org/engines.html) found in the components/ folder of Enroll. The Benefit Sponsors engine deals primarily with enrolling employees of DC based employers into employer sponsored (SHOP) coverage. The will provide a high level technical overview to help both technical and non technical users gain a basic understanding of the Benefit Sponsors engine.

Cucumbers will be linked to each section. Non technical users can read more detailed steps for each feature and developers can boot an instance of Enroll locally to "watch" the Cucumbers by enabling the browser in the Cucumber configuration to get a better visualization and technical overview of each steps.

## Basic User Interface Walkthrough and Essential Models Overview

# Employer
Assuming an environment is loaded with the proper backend data, the primary prerequisite for enrolling an employee is an employer representative creating an Employer account. This is achieved through the following steps:

1. Visit root site URL
2. Click "Employer Portal" link
3. Fill out employer info
4. Having that employee account approved by an HBX Admin
5. After that, the employer representative can log in and access the Employer account.
_Developer Note: The resulting employer instantiated can vary based on the type of business created, but a typical business could be searched with a backend query such as: `BenefitSponsors::Organizations::Organization.where(legal_name: "Legal Name").first`._

*Relevant Cucumbers*
-[All Employer Related Cucumbers](https://github.com/dchbx/enroll/tree/master/features/employers) - look at all files ending with .feature

# Benefit Sponsorships
Attached to the instantiated Oragnization/Employer record will be "many" Benefit Sponsorships.
_Developer Note: Benefit Sponsorships can be accessed with `BenefitSponsors::Organizations::Organization.where(legal_name: "Legal Name").first.benefit_sponsorships`_

# Benefit Applications

Benefit Applications contain information such as when the coverage starts, ends, when open enrollment starts, and number of full time/part time/Medicare Second Payer employees. This be instantiated through the following steps:

1. Login as Employer/HBX Admin/Broker
2. On the Employer portal, click the "Benefits" tab on the left side of the page.
3. Click "Add Plan Year". _Developer Note: This is the `benefit_applications/new?tab=benefits` page_.
4. Click "Continue"

_Developer Note: Benefit Applications can be accessed with a query such as `BenefitSponsors::Organizations::Organization.where(legal_name: "Legal Name").first.benefit_sponsorships.last.benefit_applications`_

*Relevant Cucumbers*
-[All Benefit Application Related Cucumbers](https://github.com/dchbx/enroll/tree/master/features/employers/benefit_applications) - look at all files ending with .feature

# Benefit Packages

Benefit packages contain the information for the employer's choice of benefits being offered to employees- health or dental benefits- and which carriers are being offered. They can be instantiated through the following steps:

1. After creating a benefit application and clicking "Continue", you will arrive to the create benefit packages pacge. _Developer Note: This is the `benefit_packages/new` action_.
2. Fill out the benefit package's name, description, and when employees will become eligible (Example: "First of the month following or coincinciding with date of hire.")
3. Select by carrier/metal level/single plan, reference plans, contribution amounts, and click "Create Plan Year."

_Developer Note: Benefit Packages can be accessed with a query such as `BenefitSponsors::Organizations::Organization.where(legal_name: "Legal Name").first.benefit_sponsorships.last.benefit_applications.last.benefit_packages`_


## Other Models Overview

# Business Policies

The benefit sponsors models folder also contains _policy_ files to hold certain business validation rules for Affordable Care Act (ACA) compliance. Examples of these include the minimum participation rule for benefits or waived member eligibility.

Most of these rules can be configured in the application wide [Settings](https://github.com/dchbx/enroll/blob/master/config/settings.yml) YML file.

*Relevant Files*
- [ACA SHOP Enrollment Eligibility Policy](https://github.com/dchbx/enroll/blob/master/components/benefit_sponsors/app/models/benefit_sponsors/benefit_applications/aca_shop_enrollment_eligibility_policy.rb)

# Exporters

# Importers

# Model Events

# Observers

# Subscribers

## Technical Best Practices

# Resource Registry

Because Benefit Sponsors is an engine, the main Enroll app should be able to run without it being enabled. Ideacrew's [Resource Registry](https://github.com/ideacrew/resource_registry) gem can be used to define when features should be activated.

# Benefit Sponsors MVC Take - Service and Form Clean Patterns

Like any Rails application, the Benefit Sponsors engine follows MVC patterns, but with a twist: utilizing a "Services" and "Forms" pattern to keep controllers cleaner and more readable. An example could be the following controller action:

`
module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationsController < ApplicationController
      def new
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_new(params.permit(:benefit_sponsorship_id))
        authorize @benefit_application_form, :updateable?
      end
      def create
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.for_create(application_params)
        authorize @benefit_application_form, :updateable?
        if @benefit_application_form.save
          redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_application_form.service.benefit_sponsorship, @benefit_application_form.show_page_model)
        else
          flash[:error] = error_messages(@benefit_application_form)
          redirect_to new_benefit_sponsorship_benefit_application_path(@benefit_application_form.benefit_sponsorship_id)
        end
      end
`


Attributes for the forms will be encapsulated in the `BenefitApplicationForm` class, while the bulk of the validations will be encapsulated in the `BenefitApplicationService` class.