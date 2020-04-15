# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HbxEnrollments::Operations::Persist, dbclean: :after_each do

  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:census_employee) do
    census_employee = FactoryBot.create(:census_employee, aasm_state: 'eligible', coverage_terminated_on: TimeKeeper.date_of_record.next_month.end_of_month)
    census_employee.aasm_state = "employment_terminated"
    census_employee.save
    census_employee
  end
  let(:employee_role) { FactoryBot.create(:employee_role, person: person, census_employee: census_employee) }
  let!(:hbx_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      effective_on: TimeKeeper.date_of_record.beginning_of_month,
                      terminated_on: TimeKeeper.date_of_record.next_month.end_of_month,
                      aasm_state: "coverage_terminated",
                      employee_role_id: employee_role.id,
                      household: family.active_household, family: family)
  end
  let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

  let(:params) do
    {kind: "employer_sponsored", enrollment_kind: "open_enrollment", coverage_kind: "health",
     employee_role_id: employee_role.id, benefit_group_id: BSON::ObjectId.new, benefit_group_assignment_id: BSON::ObjectId.new,
     benefit_sponsorship_id: BSON::ObjectId.new, sponsored_benefit_package_id: BSON::ObjectId.new, sponsored_benefit_id: BSON::ObjectId.new,
     rating_area_id: BSON::ObjectId.new, terminated_on: TimeKeeper.date_of_record.end_of_month, termination_submitted_on: TimeKeeper.date_of_record,
     changing: false, effective_on: TimeKeeper.date_of_record.beginning_of_month, hbx_id: "1234", submitted_at: TimeKeeper.date_of_record,
     aasm_state: "coverage_terminated", is_active: true, review_status: "incomplete", predecessor_enrollment_id: hbx_enrollment.id,
     external_enrollment: false, family_id: BSON::ObjectId.new, household_id: BSON::ObjectId.new,
     product_id: BSON::ObjectId.new, issuer_profile_id: BSON::ObjectId.new,
     hbx_enrollment_members: [{applicant_id: BSON::ObjectId.new, is_subscriber: true,
                               applied_aptc_amount: {cents: 0.0, currency_iso: "USD"},
                               eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record}]}
  end

  context 'on persists' do
    before do
      @result = subject.call(params, true)
      hbx_enrollment.reload
      census_employee.reload
    end

    it 'should be HbxEnrollments instance' do
      expect(@result.success).to be_a HbxEnrollment
    end

    it "should create new enrollment" do
      expect(HbxEnrollment.all.count).to eq 2
      expect(@result.success).to eq HbxEnrollment.where(:hbx_id.ne => hbx_enrollment.hbx_id).first
    end

    it "new enrollment created should be in term status" do
      expect(@result.success.aasm_state).to eq "coverage_terminated"
    end

    it "should reterm parent enrollment" do
      expect(hbx_enrollment.coverage_reterminated?).to eq true
    end

    it "retermed parent enrollment should be coverage_reterminated state" do
      expect(hbx_enrollment.aasm_state).to eq "coverage_reterminated"
    end

    it "new enrollment termination date shuould be less than parent enrollment" do
      expect(@result.success.terminated_on).to be < hbx_enrollment.terminated_on
    end

    it "should set parent_enrollment_id on new enrollment" do
      expect(@result.success.predecessor_enrollment_id).to eq hbx_enrollment.id
      expect(@result.success.parent_enrollment).to eq hbx_enrollment
    end

    it "should update census record coverage termination data to new enrollment term date" do
      expect(census_employee.coverage_terminated_on).to eq @result.success.terminated_on
    end

    it "new enrollment created should be in cancel status when new term date == effective date" do
      params[:terminated_on] = params[:effective_on]
      @result = subject.call(params, true)
      expect(@result.success.aasm_state).to eq "coverage_canceled"
    end

    it "should notify enrollment event" do
      expect_any_instance_of(HbxEnrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated",
                                                                     {:reply_to => glue_event_queue_name,
                                                                      "hbx_enrollment_id" => @result.success.hbx_id,
                                                                      "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                                      "is_trading_partner_publishable" => true})
      @result = subject.call(params, true)
    end
  end

end