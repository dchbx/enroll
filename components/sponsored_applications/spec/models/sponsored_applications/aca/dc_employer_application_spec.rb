require 'rails_helper'

module SponsoredApplications
  RSpec.describe Aca::DcEmployerApplication, type: :model, dbclean: :after_each do


    let(:first_day_of_this_month)           { Date.today.beginning_of_month }
    let(:first_day_of_next_month)           { Date.today.next_month.beginning_of_month }
    let(:last_day_of_this_month_next_year)  { Date.today.next_year.end_of_month }
    let(:kind)                              { :dc_employer }
    let(:effective_term)                    { first_day_of_next_month..last_day_of_this_month_next_year }
    let(:open_enrollment_term)              { first_day_of_this_month..first_day_of_this_month + 10.days }
    let(:benefit_groups)                    { [FactoryGirl.create(:sponsored_applications_benefit_group)] }

    let(:valid_params) do 
      {
        kind: kind,
        effective_term: effective_term,
        open_enrollment_term: open_enrollment_term,
        # benefit_groups: benefit_groups,
      }
    end

    context ".new" do
      context "with no arguments" do
        let(:params) {{}}

        it "should not save" do
          expect(Aca::DcEmployerApplication.new(**params).save).to be_falsey
        end
      end

      context "with no effective term" do
        let(:params) {valid_params.except(:effective_term)}

        it "should fail validation" do
          expect(Aca::DcEmployerApplication.create(**params).errors[:effective_term].any?).to be_truthy
        end
      end

      context "with no open enrollment term" do
        let(:params) {valid_params.except(:open_enrollment_term)}

        it "should fail validation" do
          expect(Aca::DcEmployerApplication.create(**params).errors[:open_enrollment_term].any?).to be_truthy
        end
      end

      context "with all valid arguments" do
        let(:params) { valid_params }
        let(:employer_application) { Aca::DcEmployerApplication.new(**params) }

        it "should be valid" do
          expect(employer_application.valid?).to be_truthy
        end

        it "should save" do
          expect(employer_application.save).to be_truthy
        end

        context "and it is saved" do
          let!(:saved_employer_application) do
            application = employer_application
            application.save
            application
          end

          it "should be findable" do
            expect(Aca::DcEmployerApplication.find(saved_employer_application.id).id.to_s).to eq saved_employer_application.id.to_s
          end
        end
      end


    end

  end
end
