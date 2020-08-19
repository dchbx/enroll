require 'rails_helper'

RSpec.describe FinancialAssistance::Income, type: :model, dbclean: :after_each do
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:household) { family.households.first }
  let(:application) { FactoryGirl.create(:application, family: family) }
  let(:tax_household) {FactoryGirl.create(:tax_household, household: household, effective_ending_on: nil, application_id: application.id)}
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

  context "valid income" do
    it "should save step_1" do
      expect(FinancialAssistance::Income.create(valid_params).valid?(:step_1)).to be_truthy
    end

    it "should save submission" do
      expect(FinancialAssistance::Income.create(valid_params).valid?(:submission)).to be_truthy
    end
  end

  describe 'find' do
    let!(:income) { FactoryGirl.create(:financial_assistance_income, applicant: applicant) }

    context 'when proper applicant id is sent' do
      it 'should return the applicant instance' do
        instance = ::FinancialAssistance::Income.find income.id
        expect(instance).to eq income
      end
    end

    context 'when wrong id is sent' do
      it 'should return nil' do
        instance = ::FinancialAssistance::Income.find application.id
        expect(instance).to be_nil
      end
    end
  end

  describe "validations" do
    let(:income){FinancialAssistance::Income.new}

    context "on step_1 and submission title validations" do
      it "with a missing title on step_1" do
        income.title = nil
        income.valid?(:step_1)
        expect(income.errors["title"]).to be_empty
      end

      it "with a missing title on submission" do
        income.title = nil
        income.valid?(:submission)
        expect(income.errors["title"]).to be_empty
      end

      it "pick a name length between 3..30 on step_1" do
        income.title = 'Te'
        income.valid?(:step_1)
        expect(income.errors["title"]).to include("pick a name length between 3..30")
      end

      it "pick a name length between 3..30 on submission" do
        income.title = 'Te'
        income.valid?(:submission)
        expect(income.errors["title"]).to include("pick a name length between 3..30")
      end

      it "pick a name length between 3..30 on step_1" do
        income.title = "Lorem Ipsum is simply dummy text of the printing and typesetting industry"
        income.valid?(:step_1)
        expect(income.errors["title"]).to include("pick a name length between 3..30")
      end

      it "pick a name length between 3..30 on submission" do
        income.title = "Lorem Ipsum is simply dummy text of the printing and typesetting industry"
        income.valid?(:submission)
        expect(income.errors["title"]).to include("pick a name length between 3..30")
      end

      it "should be valid on step_1" do
        income.amount = 'Test'
        income.valid?(:step_1)
        expect(income.errors["title"]).to be_empty
      end

      it "should be valid on submission" do
        income.valid?(:submission)
        expect(income.errors["title"]).to be_empty
      end
    end

    context "on step_1 and submission amount validations" do
      it "with a missing amount on step_1" do
        income.amount = nil
        income.valid?(:step_1)
        expect(income.errors["amount"]).to include("can't be blank")
      end

      it "with a missing amount on submission" do
        income.amount = nil
        income.valid?(:submission)
        expect(income.errors["amount"]).to include("can't be blank")
      end

      it "amount must be greater than $0 on step_1" do
        income.amount = 0
        income.valid?(:step_1)
        expect(income.errors["amount"]).to include("0.0 must be greater than $0")
      end

      it "amount must be greater than $0 on submission" do
        income.amount = 0
        income.valid?(:submission)
        expect(income.errors["amount"]).to include("0.0 must be greater than $0")
      end

      it "should be valid on step_1" do
        income.amount = 10
        income.valid?(:step_1)
        expect(income.errors["amount"]).to be_empty
      end

      it "should be valid on submission" do
        income.amount = 10
        income.valid?(:submission)
        expect(income.errors["amount"]).to be_empty
      end
    end

    context "if step_1 and submission kind validations" do
      it "with a missing kind on step_1" do
        income.kind = nil
        income.valid?(:step_1)
        expect(income.errors["kind"]).to include("can't be blank")
      end

      it "with a missing kind on submission" do
        income.kind = nil
        income.valid?(:submission)
        expect(income.errors["kind"]).to include("can't be blank")
      end

      it "is not a valid income type on step_1" do
        income.kind = 'self_employee'
        income.valid?(:step_1)
        expect(income.errors["kind"]).to include("self_employee is not a valid income type")
      end

      it "is not a valid income type on submission" do
        income.kind = 'self_employee'
        income.valid?(:submission)
        expect(income.errors["kind"]).to include("self_employee is not a valid income type")
      end

      it "should be valid on step_1" do
        income.kind = 'capital_gains'
        income.valid?(:step_1)
        expect(income.errors["kind"]).to be_empty
      end

      it "should be valid on submission" do
        income.kind = 'capital_gains'
        income.valid?(:submission)
        expect(income.errors["kind"]).to be_empty
      end
    end

    context "if step_1 and submission frequency_kind validations" do
      it "with a missing frequency_kind on step_1" do
        income.frequency_kind = nil
        income.valid?(:step_1)
        expect(income.errors["frequency_kind"]).to include("can't be blank")
      end

      it "with a missing frequency_kind on submission" do
        income.frequency_kind = nil
        income.valid?(:submission)
        expect(income.errors["frequency_kind"]).to include("can't be blank")
      end

      it "is not a valid frequency on step_1" do
        income.frequency_kind = 'self_employee'
        income.valid?(:step_1)
        expect(income.errors["frequency_kind"]).to include("self_employee is not a valid frequency")
      end

      it "is not a valid frequency on submission" do
        income.frequency_kind = 'self_employee'
        income.valid?(:submission)
        expect(income.errors["frequency_kind"]).to include("self_employee is not a valid frequency")
      end

      it "should be valid on step_1" do
        income.frequency_kind = 'monthly'
        income.valid?(:step_1)
        expect(income.errors["frequency_kind"]).to be_empty
      end

      it "should be valid on submission" do
        income.frequency_kind = 'monthly'
        income.valid?(:submission)
        expect(income.errors["frequency_kind"]).to be_empty
      end
    end

    context "if step_1 and submission start_on validations" do
      it "with a missing start_on step_1" do
        income.start_on = nil
        income.valid?(:step_1)
        expect(income.errors["start_on"]).to include("can't be blank")
      end

      it "with a missing start_on on submission" do
        income.start_on = nil
        income.valid?(:submission)
        expect(income.errors["start_on"]).to include("can't be blank")
      end

      it "should be valid on step_1" do
        income.start_on = Date.today
        income.valid?(:step_1)
        expect(income.errors["start_on"]).to be_empty
      end

      it "should be valid on submission" do
        income.start_on = Date.today
        income.valid?(:submission)
        expect(income.errors["start_on"]).to be_empty
      end
    end

    context "if end on date occur before start on date" do
      it "validate end on date can't occur before start on date" do
        income.start_on = Date.today
        income.end_on = Date.today - 10.days
        income.valid?
        expect(income.errors["end_on"]).to include("Date can't occur before start on date")
      end
    end
  end

  context "Hours worked per week" do
    let(:income) {
      FactoryGirl.create(:financial_assistance_income, applicant: applicant)
    }

    it "hours_worked_per_week" do
      expect(income.hours_worked_per_week).to eql(nil)
    end
  end
end
