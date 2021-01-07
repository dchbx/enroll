require 'rails_helper'

module BenefitSponsors
  RSpec.describe Forms::BenefitApplicationForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Forms::BenefitApplicationForm.new }
    let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
    let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
    let!(:employer_profile)    { organization.employer_profile }
    let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

    describe "model attributes" do
      it {
        [:start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on, :admin_datatable_action].each do |key|
          expect(subject.attributes.has_key?(key)).to be_truthy
        end
      }
    end

    describe "validate Form" do

      let(:valid_params) {
        {
          :benefit_sponsorship_id => "id",
          :start_on => TimeKeeper.date_of_record + 3.months,
          :end_on => TimeKeeper.date_of_record + 1.year + 3.months  - 1.day,
          :open_enrollment_start_on => TimeKeeper.date_of_record + 2.months,
          :open_enrollment_end_on => TimeKeeper.date_of_record + 2.months + 20.day
        }
      }

      let(:invalid_params) {
        {
          :benefit_sponsorship_id => nil,
          :start_on => TimeKeeper.date_of_record + 3.months,
          :end_on =>  TimeKeeper.date_of_record + 1.year + 3.months  - 1.day,
          :open_enrollment_start_on => TimeKeeper.date_of_record + 2.months,
          :open_enrollment_end_on => TimeKeeper.date_of_record + 2.months + 20.day
        }
      }

      context "with invalid params" do

        let(:build_benefit_application_form) { BenefitSponsors::Forms::BenefitApplicationForm.new(invalid_params)}

        it "should return false" do
          expect(build_benefit_application_form.valid?).to be_falsey
        end
      end

      context "with valid params" do

        let(:build_benefit_application_form) { BenefitSponsors::Forms::BenefitApplicationForm.new(valid_params)}

        it "should return true" do
          expect(build_benefit_application_form.valid?).to be_truthy
        end
      end
    end

    describe "#for_new" do
      let(:benefit_application_form) { FactoryBot.build(:benefit_sponsors_forms_benefit_application)}

      it "should assign benefit sponsorship" do
        form = BenefitSponsors::Forms::BenefitApplicationForm.for_new({:benefit_sponsorship_id => "rspec-id"})
        expect(form.service).to be_instance_of(BenefitSponsors::Services::BenefitApplicationService)
        expect(form.start_on_options).not_to be nil
        expect(form.benefit_sponsorship_id).to eq "rspec-id"
      end
    end

    describe "#for_create" do
      let(:params) {
        {
          :start_on => (TimeKeeper.date_of_record.beginning_of_month + 2.months).strftime("%m/%d/%Y"),
          :end_on => (TimeKeeper.date_of_record.beginning_of_month + 1.year + 2.months - 1.day).strftime("%m/%d/%Y"),
          :open_enrollment_start_on => (TimeKeeper.date_of_record.beginning_of_month).strftime("%m/%d/%Y"),
          :open_enrollment_end_on => (TimeKeeper.date_of_record.beginning_of_month + 1.month + Settings.aca.shop_market.open_enrollment.monthly_end_on.days).strftime("%m/%d/%Y"),
          :has_active_ba => false
        }
      }

      it "should create the form assign the params for forms" do
        form = BenefitSponsors::Forms::BenefitApplicationForm.for_create(params)
        expect(form.start_on).to eq params[:start_on]
        expect(form.open_enrollment_end_on).to eq params[:open_enrollment_end_on]
        expect(form.start_on_options).not_to be nil
      end
    end

    describe ".submit_application" do
      let(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_package, benefit_sponsorship: benefit_sponsorship) }
      let(:benefit_application_form) { BenefitSponsors::Forms::BenefitApplicationForm.new(id: benefit_application.id) }
      let!(:service_object) { double("BenefitApplicationService")}
      context "has to submit application and" do
        it "should return true if service has no application errors" do
          allow(BenefitSponsors::Services::BenefitApplicationService).to receive(:new).and_return(service_object)
          allow(service_object).to receive(:submit_application).with(benefit_application_form).and_return([true, benefit_application])
          expect(benefit_application_form.submit_application).to be_truthy
        end

        it "should return false if service has application errors" do
          allow(BenefitSponsors::Services::BenefitApplicationService).to receive(:new).and_return(service_object)
          allow(service_object).to receive(:submit_application).with(benefit_application_form).and_return([false, benefit_application])
          expect(benefit_application_form.submit_application).to be_falsy
        end
      end
    end

    describe ".force_submit_application_with_eligibility_errors" do
      let(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application, benefit_sponsorship:benefit_sponsorship) }
      let(:benefit_application_form) { BenefitSponsors::Forms::BenefitApplicationForm.new(id: benefit_application.id) }
      let!(:service_object) { double("BenefitApplicationService")}
      context "has to force submit application and" do
        it "should return true" do
          allow(BenefitSponsors::Services::BenefitApplicationService).to receive(:new).and_return(service_object)
          allow(service_object).to receive(:force_submit_application_with_eligibility_errors).with(benefit_application_form).and_return([true, benefit_application])
          expect(benefit_application_form.force_submit_application_with_eligibility_errors).to be_truthy
        end
      end
    end

    describe ".revert" do
      let(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application, benefit_sponsorship:benefit_sponsorship) }
      let(:benefit_application_form) { BenefitSponsors::Forms::BenefitApplicationForm.new(id: benefit_application.id) }
      let!(:service_object) { double("BenefitApplicationService")}
      context "has to revert back and" do
        it "should return true if benefit application has no errors" do
          allow(BenefitSponsors::Services::BenefitApplicationService).to receive(:new).and_return(service_object)
          allow(service_object).to receive(:revert).with(benefit_application_form).and_return([true, benefit_application])
          expect(benefit_application_form.revert).to be_truthy
        end

        it "should return false if benefit application has errors" do
          allow(BenefitSponsors::Services::BenefitApplicationService).to receive(:new).and_return(service_object)
          allow(service_object).to receive(:revert).with(benefit_application_form).and_return([false, benefit_application])
          expect(benefit_application_form.revert).to be_falsy
        end
      end
    end

    describe ".persist" do
      let(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application, benefit_sponsorship:benefit_sponsorship) }
      let(:benefit_application_form) { FactoryBot.build(:benefit_sponsors_forms_benefit_application)}
      let!(:service_object) { double("BenefitApplicationService")}
      context "save request received" do
        it "should save successfully if update request received false" do
          allow(BenefitSponsors::Services::BenefitApplicationService).to receive(:new).and_return(service_object)
          allow(service_object).to receive(:save).with(benefit_application_form).and_return([true, benefit_application])
          expect(benefit_application_form.persist(update: false)).to be_truthy
        end

        it "should return false if application has errors" do
          allow(BenefitSponsors::Services::BenefitApplicationService).to receive(:new).and_return(service_object)
          allow(service_object).to receive(:save).with(benefit_application_form).and_return([false, benefit_application])
          expect(benefit_application_form.persist(update: false)).to be_falsy
        end
      end

      context "update request received" do
        it "should update successfully if update request received true" do
          allow(BenefitSponsors::Services::BenefitApplicationService).to receive(:new).and_return(service_object)
          allow(service_object).to receive(:update).with(benefit_application_form).and_return([true, benefit_application])
          expect(benefit_application_form.persist(update: true)).to be_truthy
        end

        it "should return false if update request for application has errors" do
          allow(BenefitSponsors::Services::BenefitApplicationService).to receive(:new).and_return(service_object)
          allow(service_object).to receive(:update).with(benefit_application_form).and_return([false, benefit_application])
          expect(benefit_application_form.persist(update: true)).to be_falsy
        end
      end
    end

    describe 'validate form for dt action' do
      let(:valid_params) {
        {
          admin_datatable_action: true,
          benefit_sponsorship_id: 'id',
          start_on: TimeKeeper.date_of_record + 3.months,
          end_on: TimeKeeper.date_of_record + 1.year + 3.months  - 1.day,
          open_enrollment_start_on: TimeKeeper.date_of_record + 2.months,
          open_enrollment_end_on: TimeKeeper.date_of_record + 2.months + 20.day
        }
      }

      let(:invalid_params) {
        {
          admin_datatable_action: true,
          benefit_sponsorship_id: 'id',
          start_on: TimeKeeper.date_of_record + 3.months,
          end_on:  TimeKeeper.date_of_record + 1.year + 3.months  - 1.day,
          open_enrollment_start_on: TimeKeeper.date_of_record + 2.months + 20.day,
          open_enrollment_end_on: TimeKeeper.date_of_record + 2.months
        }
      }

      context 'for valid params' do
        before :each do
          @ba_form1 = ::BenefitSponsors::Forms::BenefitApplicationForm.new(valid_params)
        end

        it 'should return true when validated' do
          expect(@ba_form1.valid?).to be_truthy
        end
      end

      context 'for invalid params' do
        before :each do
          @ba_form2 = ::BenefitSponsors::Forms::BenefitApplicationForm.new(invalid_params)
        end

        it 'should return false when validated' do
          expect(@ba_form2.valid?).to be_falsey
        end

        it 'should add errors to the form instance' do
          @ba_form2.valid?
          expect(@ba_form2.errors.full_messages).to include("Open Enrollment Start Date can't be later than the Open Enrollment End Date")
        end
      end
    end

    describe 'validate form for oe dates - non admin' do

      let(:start_on) { TimeKeeper.date_of_record + 3.months }
      let(:oe_start_on) { TimeKeeper.date_of_record + 2.months }

      let(:valid_params) do
        {
          admin_datatable_action: false,
          benefit_sponsorship_id: 'id',
          start_on: start_on,
          end_on: start_on.next_year.prev_day,
          open_enrollment_start_on: oe_start_on,
          open_enrollment_end_on: oe_start_on.next_week
        }
      end

      let(:invalid_params) do
        {
          admin_datatable_action: false,
          benefit_sponsorship_id: 'id',
          start_on: start_on,
          end_on: start_on.next_year.prev_day,
          open_enrollment_start_on: oe_start_on,
          open_enrollment_end_on: oe_start_on
        }
      end

      context 'for valid params' do
        before :each do
          @ba_form1 = ::BenefitSponsors::Forms::BenefitApplicationForm.new(valid_params)
        end

        it 'should return true when validated' do
          expect(@ba_form1.valid?).to be_truthy
        end
      end

      context 'for invalid params' do
        before :each do
          @ba_form2 = ::BenefitSponsors::Forms::BenefitApplicationForm.new(invalid_params)
        end

        it 'should return false when validated' do
          expect(@ba_form2.valid?).to be_falsey
        end

        it 'should add errors to the form instance' do
          @ba_form2.valid?
          expect(@ba_form2.errors.full_messages).to include("Open Enrollment Dates are not valid")
        end
      end
    end
  end
end
