require 'rails_helper'

RSpec.describe FinancialAssistance::Benefit, type: :model, dbclean: :after_each do
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
  let(:application) {FactoryGirl.create(:application, family: family)}
  let(:household) { family.households.first }
  let(:tax_household) {FactoryGirl.create(:tax_household, household: household, effective_ending_on: nil)}
  let(:family_member) { family.primary_applicant }
  let(:applicant) {FactoryGirl.create(:applicant, tax_household_id: tax_household.id, application: application, family_member_id: family_member.id)}
  let(:benefit) {FinancialAssistance::Benefit.new(applicant: applicant)}
  let(:valid_params) {
    {
        applicant: applicant,
        title: "Financial Benefit",
        kind: 'is_eligible',
        insurance_kind: "medicare_part_b",
        start_on: Date.today
    }
  }

  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
  end

  context "valid benefit" do
    it "should save benefit step_1 and submit" do
      expect(FinancialAssistance::Benefit.create(valid_params).valid?(:step_1)).to be_truthy
      expect(FinancialAssistance::Benefit.create(valid_params).valid?(:submit)).to be_truthy
    end
  end

  describe 'find' do
    before :each do
      benefit.save!
    end

    context 'when proper applicant id is sent' do
      it 'should return the applicant instance' do
        instance = ::FinancialAssistance::Benefit.find benefit.id
        expect(instance).to eq benefit
      end
    end

    context 'when wrong id is sent' do
      it 'should return nil' do
        instance = ::FinancialAssistance::Benefit.find application.id
        expect(instance).to be_nil
      end
    end
  end

  describe 'validations' do
    context 'for title size range on step_1 and submission' do
      it 'with an empty title on step_1' do
        benefit.title = nil
        benefit.valid?(:step_1)
        expect(benefit.errors['title']).to be_empty
      end

      it 'with an empty title on submission' do
        benefit.title = nil
        benefit.valid?(:submission)
        expect(benefit.errors['title']).to be_empty
      end

      it 'with a title less than size range on step_1' do
        benefit.title='TI'
        benefit.valid?(:step_1)
        expect(benefit.errors['title']).to include('pick a name length between 3..30')
      end

      it 'with a title less than size range on submission' do
        benefit.title='TI'
        benefit.valid?(:submission)
        expect(benefit.errors['title']).to include('pick a name length between 3..30')
      end

      it 'with a title more than size range on step_1' do
        benefit.title = 'HELLO TITLE I AM EXPECTING YOU TO BE OUT OF RANGE'
        benefit.valid?(:step_1)
        expect(benefit.errors['title']).to include('pick a name length between 3..30')
      end

      it 'with a title more than size range on submission' do
        benefit.title = 'HELLO TITLE I AM EXPECTING YOU TO BE OUT OF RANGE'
        benefit.valid?(:submission)
        expect(benefit.errors['title']).to include('pick a name length between 3..30')
      end
    end

    context 'for kind on step_1 and submission' do
      context 'if kind is eligible' do
        it 'is valid on step_1' do
          benefit.kind = 'is_eligible'
          benefit.valid?(:step_1)
          expect(benefit.errors['kind']).to be_empty
        end

        it 'is valid on submission' do
          benefit.kind = 'is_eligible'
          benefit.valid?(:submission)
          expect(benefit.errors['kind']).to be_empty
        end
      end

      context 'if kind is empty' do
        it 'is invalid on step_1' do
          benefit.kind = nil
          benefit.valid?(:step_1)
          expect(benefit.errors['kind']).to include(" is not a valid benefit kind type")
        end

        it 'is invalid on submission' do
          benefit.kind = nil
          benefit.valid?(:submission)
          expect(benefit.errors['kind']).to include(" is not a valid benefit kind type")
        end
      end

      context 'if kind is enrolled' do
        it 'is valid on step_1' do
          benefit.kind = 'is_enrolled'
          benefit.valid?(:step_1)
          expect(benefit.errors["kind"]).to be_empty
        end

        it 'is valid on submission' do
          benefit.kind = 'is_enrolled'
          benefit.valid?(:submission)
          expect(benefit.errors["kind"]).to be_empty
        end
      end
    end

    context 'for insurance_kind on step_1 and submission' do
      context 'if insurance_kind is empty' do
        it 'is invalid on step_1' do
          benefit.insurance_kind = nil
          benefit.valid?(:step_1)
          expect(benefit.errors['insurance_kind']).to include("can't be blank")
        end

        it 'is invalid on submission' do
          benefit.insurance_kind = nil
          benefit.valid?(:submission)
          expect(benefit.errors['insurance_kind']).to include("can't be blank")
        end
      end

      context 'if insurance_kind is not a valid type' do
        it 'is invalid on step_1' do
          benefit.insurance_kind = 'TEST'
          benefit.valid?(:step_1)
          expect(benefit.errors['insurance_kind']).to include('TEST is not a valid benefit insurance kind type')
        end

        it 'is invalid on submission' do
          benefit.insurance_kind = 'TEST'
          benefit.valid?(:submission)
          expect(benefit.errors['insurance_kind']).to include('TEST is not a valid benefit insurance kind type')
        end
      end
    end
  end

  #Rspec for testing method  "is_eligible?"
  describe 'rspecs for methods' do
    context "if kind method is eligible" do
      it "should be valid" do
        benefit.kind = "is_eligible"
        expect(benefit.is_eligible?).to be_truthy
      end

      it "should be invalid" do
        benefit.kind = "is_enrolled"
        expect(benefit.is_eligible?).to be_falsey
      end
    end

    context 'if insurance_kind is a employer_sponsored_insurance' do
      context 'if any of 6 fields are blank' do
        it 'should be invalid on step_1' do
          benefit.insurance_kind = "employer_sponsored_insurance"
          benefit.employer_id = nil
          benefit.valid?(:step_1)
          expect(benefit.errors["employer_id"]).to include("' EMPLOYER IDENTIFICATION NO.(EIN)' employer id can't be blank ")

        end

        it 'should be invalid on submission' do
          benefit.insurance_kind = "employer_sponsored_insurance"
          benefit.employer_id = nil
          benefit.valid?(:submission)
          expect(benefit.errors["employer_id"]).to include("' EMPLOYER IDENTIFICATION NO.(EIN)' employer id can't be blank ")
        end
      end

      context 'if fields are not blank' do
        it 'should be valid on step_1' do
          benefit.insurance_kind = "employer_sponsored_insurance"
          benefit.employer_id = 1234
          benefit.valid?(:step_1)
          expect(benefit.errors["employer_id"]).to be_empty

        end

        it 'should be valid on submission' do
          benefit.insurance_kind = "employer_sponsored_insurance"
          benefit.employer_id = nil
          benefit.valid?(:submission)
          expect(benefit.errors["employer_id"]).to include("' EMPLOYER IDENTIFICATION NO.(EIN)' employer id can't be blank ")
        end
      end
    end

    context "if step_1 and submit employer_sponsored_insurance kind validations" do
      it "with a missing employee_cost_frequency" do
        benefit.kind = "employer_sponsored_insurance"
        benefit.employee_cost_frequency = nil
        benefit.valid?(:step_1)
        expect(benefit.errors["employee_cost_frequency"]).to be_empty
        benefit.valid?(:submission)
        expect(benefit.errors["employee_cost_frequency"]).to be_empty
      end
    end

    context "if step_1 and submit start_on validations" do
      it "with a missing start_on" do
        benefit.start_on = nil
        benefit.kind ="is_enrolled"
        benefit.valid?(:step_1)
        expect(benefit.errors["start_on"]).to include(" Start On Date must be present")
        benefit.valid?(:submission)
        expect(benefit.errors["start_on"]).to include(" Start On Date must be present")
      end

      it "should be valid" do
        benefit.start_on = Date.today
        benefit.valid?(:step_1)
        expect(benefit.errors["start_on"]).to be_empty
        benefit.valid?(:submission)
        expect(benefit.errors["start_on"]).to be_empty
      end
    end

    context "if step_1 and submit end on date occur before start on date" do
      it "end on date can't occur before start on date" do
        now= Date.today
        benefit.start_on = now
        benefit.end_on = now-90
        benefit.kind ="is_enrolled"
        benefit.valid?(:step_1)
        expect(benefit.errors["end_on"]).to include("End On Date can't occur before Start On Date")
        benefit.valid?(:submission)
        expect(benefit.errors["end_on"]).to include("End On Date can't occur before Start On Date")
      end
    end
  end
end