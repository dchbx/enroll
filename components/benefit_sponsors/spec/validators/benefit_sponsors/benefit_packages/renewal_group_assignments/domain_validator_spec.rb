# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::BenefitPackages::RenewalGroupAssignments::DomainValidator do
  let(:validator) { BenefitSponsors::BenefitPackages::RenewalGroupAssignments::DomainValidator.new }
  let(:benefit_package_id) { BSON::ObjectId.new }
  let(:census_employee_id) { BSON::ObjectId.new }

  let(:base_valid_params) do
    {
      :benefit_package_id => benefit_package_id,
      :census_employee_id => census_employee_id
    }
  end

  describe "given valid parameters" do
    subject { validator.call(base_valid_params) }
    let(:census_employee) { double }
    let(:benefit_package) { double }

    before(:each) do
      allow(BenefitSponsors::BenefitPackages::BenefitPackage).to receive(
        :find
      ).with(benefit_package_id).and_return(benefit_package)
      allow(CensusEmployee).to receive(
        :find
      ).with(census_employee_id).and_return(census_employee)
    end

    it "is valid" do
      expect(subject.success?).to be_truthy
    end
  end

  describe "given a bogus ids" do
    let(:params) do
      base_valid_params.merge({
                                :benefit_package_id => benefit_package_id,
                                :census_employee_id => census_employee_id
                              })
    end

    before(:each) do
      allow(BenefitSponsors::BenefitPackages::BenefitPackage).to receive(
        :find
      ).with(benefit_package_id).and_return(nil)
      allow(CensusEmployee).to receive(
        :find
      ).with(census_employee_id).and_return(nil)
    end

    subject { validator.call(params) }

    it "is invalid" do
      expect(subject.success?).to be_falsey
    end

    it "has an error on the benefit_package_id" do
      expect(subject.errors.to_h).to have_key(:benefit_package_id)
    end

    it "has an error on the census_employee_id" do
      expect(subject.errors.to_h).to have_key(:census_employee_id)
    end
  end

end