require 'rails_helper'

module BenefitSponsors
  RSpec.describe Forms::BenefitApplicationForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Forms::BenefitApplicationForm.new }

    describe "model attributes" do
      it {
        [:start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on].each do |key|
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
      let(:benefit_application_form) { FactoryGirl.build(:benefit_sponsors_forms_benefit_application)}

      it "should assign benefit sponsorship" do
        form = BenefitSponsors::Forms::BenefitApplicationForm.for_new("rspec-id")
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
          :open_enrollment_end_on => (TimeKeeper.date_of_record.beginning_of_month + 1.month + Settings.aca.shop_market.open_enrollment.monthly_end_on.days).strftime("%m/%d/%Y")
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
      let!(:benefit_sponsorship) { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship)}
      let(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, benefit_sponsorship:benefit_sponsorship) }
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
      let!(:benefit_sponsorship) { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship)}
      let(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, benefit_sponsorship:benefit_sponsorship) }
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
      let!(:benefit_sponsorship) { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship)}
      let(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, benefit_sponsorship:benefit_sponsorship) }
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
      let!(:benefit_sponsorship) { FactoryGirl.build(:benefit_sponsors_benefit_sponsorship)}
      let(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, benefit_sponsorship:benefit_sponsorship) }
      let(:benefit_application_form) { FactoryGirl.build(:benefit_sponsors_forms_benefit_application)}
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


  end

end