require "rails_helper"

# Date.today converted to TimeKeeper.date_of_record

RSpec.describe BenefitSponsors::BenefitPackages::RenewalGroupAssignments::ParameterValidator do
  let(:validator) { BenefitSponsors::BenefitPackages::RenewalGroupAssignments::ParameterValidator.new }
  let(:benefit_package_id) { BSON::ObjectId.new }
  let(:census_employee_id) { BSON::ObjectId.new }
  let(:effective_on_date) { TimeKeeper.date_of_record }

  let(:base_valid_params) do
    {
      "benefit_package_id" => benefit_package_id.to_s,
      "census_employee_id" => census_employee_id.to_s,
      "effective_on_date" => effective_on_date.strftime("%Y-%m-%d")
    }
  end

  describe "given valid parameters" do
    subject { validator.call(base_valid_params) }

    it "is valid" do
      expect(subject.success?).to be_truthy
    end

    it "has the benefit package id" do
      expect(subject.output[:benefit_package_id]).to eq benefit_package_id
    end

    it "has the census_employee_id" do
      expect(subject.output[:census_employee_id]).to eq census_employee_id
    end

    it "has the effective date" do
      expect(subject.output[:effective_on_date]).to eq effective_on_date
    end
  end

  describe "given a bogus benefit package id" do
    let(:params) do
      base_valid_params.merge({
        "benefit_package_id" => "sadfjkjkksef"
      })
    end

    subject { validator.call(params) }

    it "is invalid" do
      expect(subject.success?).to be_falsey
    end

    it "has an error on the benefit_package_id" do
      expect(subject.errors.to_h).to have_key(:benefit_package_id)
    end
  end

  describe "given a bogus census employee id" do
    let(:params) do
      base_valid_params.merge({
        "census_employee_id" => "sadfjkjkksef"
      })
    end

    subject { validator.call(params) }

    it "is invalid" do
      expect(subject.success?).to be_falsey
    end

    it "has an error on the census_employee_id" do
      expect(subject.errors.to_h).to have_key(:census_employee_id)
    end
  end
end