require 'rails_helper'

RSpec.describe FinancialAssistance::Deduction, type: :model, dbclean: :after_each do
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:household) {family.households.first}
  let(:application) { FactoryGirl.create(:application, family: family) }
  let(:tax_household) {FactoryGirl.create(:tax_household, household: household, effective_ending_on: nil, application_id: application.id )}
  let(:family_member) { family.primary_applicant }
  let(:applicant) { FactoryGirl.create(:applicant, tax_household_id: tax_household.id, application: application, family_member_id: family_member.id) }


  let(:valid_params){
    {
      applicant: applicant,
      amount: 1000,
      frequency_kind: 'monthly',
      start_on: Date.today
    }
  }

  before :each do
		allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
  end

  context "valid deduction" do
    it "should save step_1" do
      expect(FinancialAssistance::Deduction.create(valid_params).valid?(:step_1)).to be_truthy
    end

    it "should save submission" do
      expect(FinancialAssistance::Deduction.create(valid_params).valid?(:submission)).to be_truthy
    end
  end

  describe 'find' do
    let!(:deduction) { FactoryGirl.create(:financial_assistance_deduction, applicant: applicant) }

    context 'when proper applicant id is sent' do
      it 'should return the applicant instance' do
        instance = ::FinancialAssistance::Deduction.find deduction.id
        expect(instance).to eq deduction
      end
    end

    context 'when wrong id is sent' do
      it 'should return nil' do
        instance = ::FinancialAssistance::Deduction.find application.id
        expect(instance).to be_nil
      end
    end
  end

  describe "validations" do
    let(:deduction){FinancialAssistance::Deduction.new}

    context "on step_1 and submission title validations" do
      it "with a missing title on step_1" do
        deduction.title = nil
        deduction.valid?(:step_1)
        expect(deduction.errors["title"]).to be_empty
      end

      it "with a missing title on submission" do   
        deduction.title = nil
        deduction.valid?(:submission)
        expect(deduction.errors["title"]).to be_empty
      end

      it "pick a name length between 3..30 on step_1" do
        deduction.title = 'Te'
        deduction.valid?(:step_1)
        expect(deduction.errors["title"]).to include("pick a name length between 3..30")
       end

      it "pick a name length between 3..30 on submission" do
      	deduction.title = 'Te'
        deduction.valid?(:submission)
        expect(deduction.errors["title"]).to include("pick a name length between 3..30")
      end

      it " pick a name length between 3..30 0n step_1" do
        deduction.title = "Lorem Ipsum is simply dummy text of the printing and typesetting industry"
        deduction.valid?(:step_1)
        expect(deduction.errors["title"]).to include("pick a name length between 3..30")
      end

      it "pick a name length between 3..30 on submission" do
      	deduction.title = "Lorem Ipsum is simply dummy text of the printing and typesetting industry"
        deduction.valid?(:submission)
        expect(deduction.errors["title"]).to include("pick a name length between 3..30")
      end

      it "should be valid on step_1" do
        deduction.amount = 'Test'
        deduction.valid?(:step_1)
        expect(deduction.errors["title"]).to be_empty
      end

      it "should be valid on submission" do
        deduction.valid?(:submission)
        expect(deduction.errors["title"]).to be_empty
      end
    end

    context "on step_1 and submission amount validations" do
      it "with a missing amount on step_1" do
        deduction.amount = nil
        deduction.valid?(:step_1)
        expect(deduction.errors["amount"]).to include("can't be blank")
      end

      it "with a missing amount on submission" do
        deduction.amount  = nil
        deduction.valid?(:submission)
        expect(deduction.errors["amount"]).to include("can't be blank")
      end

      it "amount must be greater than $0 on step_1" do
        deduction.amount = 0
        deduction.valid?(:step_1)
        expect(deduction.errors["amount"]).to include("0.0 must be greater than $0")
      end

      it "amount must be greater than $0 on submission" do
      	deduction.amount = 0
        deduction.valid?(:submission)
        expect(deduction.errors["amount"]).to include("0.0 must be greater than $0")
      end

      it "should be valid on step_1" do
        deduction.amount = 10
        deduction.valid?(:step_1)
        expect(deduction.errors["amount"]).to be_empty
      end

      it "should be valid on submission" do
      	deduction.amount = 10
        deduction.valid?(:submission)
        expect(deduction.errors["amount"]).to be_empty
      end
    end

    context "if step_1 and submission kind validations" do
      it "with a missing kind on step_1" do
        deduction.kind = nil
        deduction.valid?(:step_1)
        expect(deduction.errors["kind"]).to include("can't be blank")
      end

      it "with a missing kind on submission" do
      	deduction.kind = nil
        deduction.valid?(:submission)
        expect(deduction.errors["kind"]).to include("can't be blank")
      end

      it "is not a valid deduction type on step_1" do
        deduction.kind = 'self_employee'
        deduction.valid?(:step_1)
        expect(deduction.errors["kind"]).to include("self_employee is not a valid deduction type")
      end

      it "is not a valid deduction type on submission" do
      	deduction.kind = 'self_employee'
        deduction.valid?(:submission)
        expect(deduction.errors["kind"]).to include("self_employee is not a valid deduction type")
      end

      it "should be valid on step_1" do
        deduction.kind = 'alimony_paid'
        deduction.valid?(:step_1)
        expect(deduction.errors["kind"]).to be_empty
      end

      it "should be valid on submission" do
      	deduction.kind = 'alimony_paid'
        deduction.valid?(:submission)
        expect(deduction.errors["kind"]).to be_empty
      end

    end

    context "if step_1 and submission frequency_kind validations" do
      it "with a missing frequency_kind on step_1" do
        deduction.frequency_kind = nil
        deduction.valid?(:step_1)
        expect(deduction.errors["frequency_kind"]).to include("can't be blank")
      end

      it "with a missing frequency_kind on submission" do
      	deduction.frequency_kind = nil
        deduction.valid?(:submission)
        expect(deduction.errors["frequency_kind"]).to include("can't be blank")
      end

      it "is not a valid frequency on step_1" do
        deduction.frequency_kind = 'self_employee'
        deduction.valid?(:step_1)
        expect(deduction.errors["frequency_kind"]).to include("self_employee is not a valid frequency")
      end

      it "is not a valid frequency on submission" do
      	deduction.frequency_kind = 'self_employee'
        deduction.valid?(:submission)
        expect(deduction.errors["frequency_kind"]).to include("self_employee is not a valid frequency")
      end

      it "should be valid on step_1" do
        deduction.frequency_kind = 'monthly'
        deduction.valid?(:step_1)
        expect(deduction.errors["frequency_kind"]).to be_empty
      end

      it "should be valid on submission" do
      	deduction.frequency_kind = 'monthly'
        deduction.valid?(:submission)
        expect(deduction.errors["frequency_kind"]).to be_empty
      end

    end

    context "if step_1 and submission start_on validations" do
      it "with a missing start_on step_1" do
        deduction.start_on = nil
        deduction.valid?(:step_1)
        expect(deduction.errors["start_on"]).to include("can't be blank")
      end

      it "with a missing start_on submission" do
      	deduction.start_on = nil
        deduction.valid?(:submission)
        expect(deduction.errors["start_on"]).to include("can't be blank")
      end

      it "should be valid on step_1" do
        deduction.start_on = Date.today
        deduction.valid?(:step_1)
        expect(deduction.errors["start_on"]).to be_empty
      end

      it "should be valid on submission" do
      	deduction.start_on = Date.today
        deduction.valid?(:submission)
        expect(deduction.errors["start_on"]).to be_empty
      end

    end

    context "if step_1 and submission end on date occur before start on date" do
      it "end on date can't occur before start on date on step_1" do
        deduction.start_on = TimeKeeper.date_of_record
        deduction.end_on = TimeKeeper.date_of_record - 10.days
        deduction.valid?(:step_1)
        expect(deduction.errors["end_on"]).to include(" End On date can't occur before Start On Date")
      end

      it "end on date can't occur before start on date on submission" do
        deduction.start_on = TimeKeeper.date_of_record
        deduction.end_on = TimeKeeper.date_of_record - 10.days
        deduction.valid?(:submission)
        expect(deduction.errors["end_on"]).to include(" End On date can't occur before Start On Date")
      end
    end
  end
end
