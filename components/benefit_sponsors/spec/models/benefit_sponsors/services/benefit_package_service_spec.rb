# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Services::BenefitPackageService do
  describe "#load_employer_estimates" do
    let(:form) do
      instance_double(
        ::BenefitSponsors::Forms::BenefitPackageForm,
        sponsored_benefits: [sponsored_benefit_form],
        service: form_service
      )
    end
    let(:sponsored_benefit_form) do
      instance_double(
        BenefitSponsors::Forms::SponsoredBenefitForm,
        id: sponsored_benefit_id
      )
    end
    let(:sponsored_benefit) do
      instance_double(
        ::BenefitSponsors::SponsoredBenefits::SponsoredBenefit,
        benefit_package: benefit_package,
        reference_product: reference_product,
        product_package: product_package,
        new_record?: false
      )
    end
    let(:estimator_cost_service) do
      instance_double(
        ::BenefitSponsors::Services::SponsoredBenefitCostEstimationService
      )
    end
    let(:benefit_application) do
      instance_double(
        ::BenefitSponsors::BenefitApplications::BenefitApplication,
        benefit_packages: benefit_packages_association_proxy
      )
    end
    let(:benefit_package) do
      instance_double(
        ::BenefitSponsors::BenefitPackages::BenefitPackage,
        benefit_sponsor_catalog: nil,
        benefit_application: benefit_application,
        sponsored_benefits: sponsored_benefits_association_proxy
      )
    end
    let(:form_service) do
      instance_double(
        BenefitSponsors::Services::BenefitPackageService,
        benefit_application: benefit_application
      )
    end

    let(:benefit_packages_association_proxy) { double }
    let(:sponsored_benefits_association_proxy) { double }
    let(:benefit_package_id) { "A BENEFIT PACKAGE ID" }
    let(:sponsored_benefit_id) { BSON::ObjectId.new }

    let(:costs) do
      {
        estimated_total_cost: estimated_total_cost,
        estimated_sponsor_exposure: employer_estimated_exposure,
        estimated_enrollee_minimum: employee_estimated_min_cost,
        estimated_enrollee_maximum: employee_estimated_max_cost
      }
    end

    let(:reference_product) { double }
    let(:product_package) { double }

    let(:estimated_total_cost) { 9999 }
    let(:employer_estimated_exposure) { 7777 }
    let(:employee_estimated_min_cost) { 999 }
    let(:employee_estimated_max_cost) { 1234 }

    subject { ::BenefitSponsors::Services::BenefitPackageService.new({benefit_package_id: benefit_package_id}) }

    before :each do
      allow(::BenefitSponsors::BenefitPackages::BenefitPackage).to receive(:find).with(benefit_package_id).and_return(benefit_package)
      allow(::BenefitSponsors::Services::SponsoredBenefitCostEstimationService).to receive(:new).and_return(estimator_cost_service)
      allow(estimator_cost_service).to receive(:calculate_estimates_for_package_edit).with(
        benefit_application,
        sponsored_benefit,
        reference_product,
        product_package
      ).and_return(costs)
      allow(sponsored_benefit_form).to receive(:employer_estimated_monthly_cost=).with(employer_estimated_exposure)
      allow(sponsored_benefit_form).to receive(:employer_estimated_min_monthly_cost=).with(employee_estimated_min_cost)
      allow(sponsored_benefit_form).to receive(:employer_estimated_max_monthly_cost=).with(employee_estimated_max_cost)
      allow(benefit_packages_association_proxy).to receive(:where).with({:"sponsored_benefits._id" => sponsored_benefit_id}).and_return([benefit_package])
      allow(sponsored_benefits_association_proxy).to receive(:where).with({id: sponsored_benefit_id}).and_return([sponsored_benefit])
    end

    it "assigns the employer exposure as the total amount to the form" do
      expect(sponsored_benefit_form).to receive(:employer_estimated_monthly_cost=).with(employer_estimated_exposure)
      subject.load_employer_estimates(form)
    end

    it "assigns the correct employee minimum to the form" do
      expect(sponsored_benefit_form).to receive(:employer_estimated_min_monthly_cost=).with(employee_estimated_min_cost)
      subject.load_employer_estimates(form)
    end

    it "assigns the correct employee maximum to the form" do
      expect(sponsored_benefit_form).to receive(:employer_estimated_max_monthly_cost=).with(employee_estimated_max_cost)
      subject.load_employer_estimates(form)
    end

  end
end