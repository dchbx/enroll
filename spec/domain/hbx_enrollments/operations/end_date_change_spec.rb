# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe HbxEnrollments::Operations::EndDateChange, dbclean: :after_each do

  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:census_employee) do
    census_employee = FactoryBot.create(:census_employee, aasm_state: 'eligible', coverage_terminated_on: TimeKeeper.date_of_record.next_month.end_of_month)
    census_employee.aasm_state = "employment_terminated"
    census_employee.save
    census_employee
  end
  let(:employee_role) { FactoryBot.create(:employee_role, person: person, census_employee: census_employee) }
  let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

  let(:params) do
    {enrollment_id: hbx_enrollment.id.to_s, new_term_date: TimeKeeper.date_of_record, edi_required: true}
  end

  context "IVL end date change" do
    let!(:hbx_enrollment_member) do
      FactoryBot.build(:hbx_enrollment_member,
                       is_subscriber: true,
                       applicant_id: family.primary_applicant.id,
                       eligibility_date: TimeKeeper.date_of_record.beginning_of_month,
                       coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
                       coverage_end_on: TimeKeeper.date_of_record.next_month.end_of_month)
    end
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        kind: 'individual',
                        consumer_role_id: person.consumer_role.id,
                        effective_on: TimeKeeper.date_of_record.beginning_of_month,
                        terminated_on: TimeKeeper.date_of_record.next_month.end_of_month,
                        aasm_state: "coverage_terminated",
                        issuer_profile_id: BSON::ObjectId.new,
                        product_id: BSON::ObjectId.new,
                        household: family.active_household,
                        family: family,
                        hbx_enrollment_members: [hbx_enrollment_member])
    end

    context 'on Success' do
      before do
        @result = subject.call(params)
      end

      context 'termination' do
        it 'persist should be HbxEnrollments object' do
          expect(@result.success).to be_a HbxEnrollment
        end

        it "should return enrollment" do
          expect(@result.success).to eq HbxEnrollment.where(:hbx_id.ne => hbx_enrollment.hbx_id).first
        end

        it "enrollment should be in term status" do
          expect(@result.success.aasm_state).to eq "coverage_terminated"
        end


        it "enrollment term date should match param term date" do
          expect(@result.success.terminated_on).to eq params[:new_term_date]
        end

        it "should reterm parent enrollment" do
          expect(@result.success.parent_enrollment.coverage_reterminated?).to eq true
        end
      end

      context 'cancellation' do

        let(:params) do
          {enrollment_id: hbx_enrollment.id.to_s, new_term_date: TimeKeeper.date_of_record.beginning_of_month, edi_required: true}
        end

        it 'persist should be HbxEnrollments object' do
          expect(@result.success).to be_a HbxEnrollment
        end

        it "should return enrollment" do
          expect(@result.success).to eq HbxEnrollment.where(:hbx_id.ne => hbx_enrollment.hbx_id).first
        end

        it "enrollment should be in cancel status" do
          expect(@result.success.aasm_state).to eq "coverage_canceled"
        end


        it "enrollment term date should match param term date" do
          expect(@result.success.terminated_on).to eq params[:new_term_date]
        end

        it "should reterm parent enrollment" do
          expect(@result.success.parent_enrollment.coverage_reterminated?).to eq true
        end
      end
    end

    context 'on Failure' do

      it "should return error, when new term date is not a valid" do
        @result = subject.call({enrollment_id: hbx_enrollment.id.to_s, new_term_date: TimeKeeper.date_of_record.next_month.end_of_month, edi_required: true})
        expect(@result.failure).to eq "not a valid new term date"
      end

      it "should return error, when enrollment not found" do
        @result = subject.call({enrollment_id: BSON::ObjectId.new.to_s, new_term_date: TimeKeeper.date_of_record.next_month.end_of_month, edi_required: true})
        expect(@result.failure).to eq "policy not found"
      end

      it "should return error, when enrollment is historic 3 years old enrollment" do
        hbx_enrollment.effective_on = Date.new(2018, 12, 31)
        hbx_enrollment.save!
        @result = subject.call({enrollment_id: hbx_enrollment.id.to_s, new_term_date: TimeKeeper.date_of_record, edi_required: true})
        expect(@result.failure).to eq "not a valid policy to change end date"
      end

      it "should return error, when enrollment to change end date is not terminated enrollment" do
        hbx_enrollment.update_attributes(aasm_state: "coverage_selected")
        @result = subject.call({enrollment_id: hbx_enrollment.id.to_s, new_term_date: TimeKeeper.date_of_record, edi_required: true})
        expect(@result.failure).to eq "not a term policy"
      end

      it "should return error, when params type not valid" do
        @result = subject.call({enrollment_id: hbx_enrollment.id, new_term_date: TimeKeeper.date_of_record.next_month.end_of_month, edi_required: true})
        expect(@result.failure).to eq({:enrollment_id => ["must be a string"]})
      end

      it "should return error, when required argument missing" do
        hbx_enrollment.update_attributes(product_id: nil)
        @result = subject.call({enrollment_id: hbx_enrollment.id.to_s, new_term_date: TimeKeeper.date_of_record, edi_required: true})
        expect(@result.failure).to eq({:product_id => ["must be filled"]})
      end
    end
  end

  context "Shop end date change" do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let!(:hbx_enrollment_member) do
      FactoryBot.build(:hbx_enrollment_member,
                       is_subscriber: true, applicant_id: family.primary_applicant.id,
                       eligibility_date: TimeKeeper.date_of_record.beginning_of_month,
                       coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
                       coverage_end_on: TimeKeeper.date_of_record.next_month.end_of_month)
    end
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        effective_on: current_benefit_package.start_on,
                        terminated_on: TimeKeeper.date_of_record.next_month.end_of_month,
                        kind: "employer_sponsored",
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: current_benefit_package.id,
                        sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                        aasm_state: "coverage_terminated", employee_role_id: employee_role.id,
                        issuer_profile_id: BSON::ObjectId.new, product_id: BSON::ObjectId.new,
                        household: family.active_household, family: family,
                        benefit_group_assignment_id: BSON::ObjectId.new, rating_area_id: BSON::ObjectId.new,
                        hbx_enrollment_members: [hbx_enrollment_member])
    end

    context 'on Success' do

      before do
        @result = subject.call(params)
      end

      context 'termination' do

        it 'persist should be HbxEnrollments object' do
          expect(@result.success).to be_a HbxEnrollment
        end

        it "should return enrollment" do
          expect(@result.success).to eq HbxEnrollment.where(:hbx_id.ne => hbx_enrollment.hbx_id).first
        end

        it "enrollment should be in term status" do
          expect(@result.success.aasm_state).to eq "coverage_terminated"
        end


        it "enrollment term date should match param term date" do
          expect(@result.success.terminated_on).to eq params[:new_term_date]
        end

        it "should reterm parent enrollment" do
          expect(@result.success.parent_enrollment.coverage_reterminated?).to eq true
        end
      end

      context 'cancellation' do

        let(:params) do
          {enrollment_id: hbx_enrollment.id.to_s, new_term_date: current_benefit_package.start_on, edi_required: true}
        end

        it 'persist should be HbxEnrollments object' do
          expect(@result.success).to be_a HbxEnrollment
        end

        it "should return enrollment" do
          expect(@result.success).to eq HbxEnrollment.where(:hbx_id.ne => hbx_enrollment.hbx_id).first
        end

        it "enrollment should be in cancel status" do
          expect(@result.success.aasm_state).to eq "coverage_canceled"
        end


        it "enrollment term date should match param term date" do
          expect(@result.success.terminated_on).to eq params[:new_term_date]
        end

        it "should reterm parent enrollment" do
          expect(@result.success.parent_enrollment.coverage_reterminated?).to eq true
        end
      end
    end

    context 'on Failure' do

      it "should return error, when new term date is not a valid" do
        @result = subject.call({enrollment_id: hbx_enrollment.id.to_s, new_term_date: TimeKeeper.date_of_record.next_month.end_of_month, edi_required: true})
        expect(@result.failure).to eq "not a valid new term date"
      end

      it "should return error, when enrollment not found" do
        @result = subject.call({enrollment_id: BSON::ObjectId.new.to_s, new_term_date: TimeKeeper.date_of_record.next_month.end_of_month, edi_required: true})
        expect(@result.failure).to eq "policy not found"
      end

      it "should return error, when enrollment is historic 3 years old enrollment" do
        hbx_enrollment.effective_on = Date.new(2018, 12, 31)
        hbx_enrollment.save!
        @result = subject.call({enrollment_id: hbx_enrollment.id.to_s, new_term_date: TimeKeeper.date_of_record, edi_required: true})
        expect(@result.failure).to eq "not a valid policy to change end date"
      end

      it "should return error, when enrollment to change end date is not terminated enrollment" do
        hbx_enrollment.update_attributes(aasm_state: "coverage_selected")
        @result = subject.call({enrollment_id: hbx_enrollment.id.to_s, new_term_date: TimeKeeper.date_of_record, edi_required: true})
        expect(@result.failure).to eq "not a term policy"
      end

      it "should return error, when params type not valid" do
        @result = subject.call({enrollment_id: hbx_enrollment.id, new_term_date: TimeKeeper.date_of_record.next_month.end_of_month, edi_required: true})
        expect(@result.failure).to eq({:enrollment_id => ["must be a string"]})
      end

      it "should return error, when required argument missing" do
        hbx_enrollment.update_attributes(product_id: nil)
        @result = subject.call({enrollment_id: hbx_enrollment.id.to_s, new_term_date: TimeKeeper.date_of_record, edi_required: true})
        expect(@result.failure).to eq({:product_id => ["must be filled"]})
      end
    end
  end
end
