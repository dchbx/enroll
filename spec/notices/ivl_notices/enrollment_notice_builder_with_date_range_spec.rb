require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe IvlNotices::EnrollmentNoticeBuilderWithDateRange, dbclean: :after_each do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person, e_case_id: "family_test#1000")}
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, created_at: (TimeKeeper.date_of_record.in_time_zone("Eastern Time (US & Canada)") - 2.days), household: family.households.first, kind: "individual", aasm_state: "enrolled_contingent")}
  let!(:hbx_enrollment_member) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month )}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Enrollment Notice',
                            :notice_template => 'notices/ivl/enrollment_notice',
                            :notice_builder => 'IvlNotices::EnrollmentNoticeBuilderWithDateRange',
                            :event_name => 'enrollment_notice_with_date_range',
                            :mpi_indicator => 'IVL_ENR',
                            :title => "Enrollment notice"})
                          }
    let(:valid_params) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template,
        :options => {:hbx_enrollment_hbx_ids => [hbx_enrollment.hbx_id] }
    }}
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }

  describe "New" do
    before do
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::EnrollmentNoticeBuilderWithDateRange.new(person.consumer_role, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{IvlNotices::EnrollmentNoticeBuilderWithDateRange.new(person.consumer_role, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do

    before :each do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EnrollmentNoticeBuilderWithDateRange.new(person.consumer_role, valid_params)
      bc_period = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
      @eligibility_notice.build
    end

    it "should return coverage year" do
      expect(@eligibility_notice.notice.coverage_year).to eq hbx_enrollment.effective_on.year.to_s
    end

    it "should return coverage kind" do
      expect(@eligibility_notice.notice.enrollments.first.coverage_kind).to eq hbx_enrollment.coverage_kind
    end

    it "should return plan name" do
      expect(@eligibility_notice.notice.enrollments.first.plan.plan_name).to eq hbx_enrollment.plan.name
    end

    it "should retun carrier name" do
      expect(@eligibility_notice.notice.enrollments.first.plan.plan_carrier).to eq hbx_enrollment.plan.carrier_profile.organization.legal_name
    end

    it "should return plan deductible" do
      expect(@eligibility_notice.notice.enrollments.first.plan.deductible).to eq hbx_enrollment.plan.deductible
    end

    it "should return person full name" do
      expect(@eligibility_notice.notice.primary_fullname).to eq person.full_name.titleize
    end

    it "should return person hbx_id" do
      expect(@eligibility_notice.notice.primary_identifier).to eq person.hbx_id
    end
  end

  describe "document_due_date", dbclean: :after_each do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EnrollmentNoticeBuilderWithDateRange.new(person.consumer_role, valid_params)
    end

    context "when special verification already exists" do
      it "should not update the due date" do
        special_verification = SpecialVerification.new(due_date: Date.new(2017,5,5), verification_type: "Citizenship", type: "notice")
        person.consumer_role.special_verifications << special_verification
        person.consumer_role.save!
        @eligibility_notice.build
        expect(@eligibility_notice.document_due_date(person, "Citizenship")).to eq special_verification.due_date
      end
    end

    context "when special verification does not exist" do
      it "should update the due date" do
        special_verification = SpecialVerification.new(due_date: Date.new(2017,5,5), verification_type: "Social Security Number", type: "notice")
        person.consumer_role.special_verifications << special_verification
        person.consumer_role.save!
        @eligibility_notice.build
        date = @eligibility_notice.document_due_date(person, "Social Security Number")
        expect(date).to eq special_verification.due_date
      end
    end

    context "when individual is fully verified" do
      let(:payload) { "somepayload" }
      it "should return nil due date" do
        args = OpenStruct.new
        args.determined_at = TimeKeeper.datetime_of_record - 1.month
        args.vlp_authority = "ssa"
        person.consumer_role.lawful_presence_determination.vlp_responses << EventResponse.new({received_at: args.determined_at, body: payload})
        person.consumer_role.coverage_purchased!
        person.consumer_role.ssn_valid_citizenship_invalid!(args)
        @eligibility_notice.build
        expect(@eligibility_notice.document_due_date(person, "Social Security Number")).to eq nil
      end
    end
  end

  describe "min_notice_due_date", dbclean: :after_each do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EnrollmentNoticeBuilderWithDateRange.new(person.consumer_role, valid_params)
    end

    context "when there are outstanding verification family members" do
      let!(:person2) { FactoryGirl.create(:person, :with_consumer_role)}
      let!(:family_member2) { FactoryGirl.create(:family_member, family: family, is_active: true, person: person2) }
      let!(:hbx_enrollment_member2) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment, applicant_id: family_member2.id, eligibility_date: TimeKeeper.date_of_record.prev_month)}
      it "should return a future date when present" do
        special_verification = SpecialVerification.new(due_date: TimeKeeper.date_of_record.prev_day, verification_type: "Social Security Number", type: "notice")
        person.consumer_role.special_verifications << special_verification
        person.consumer_role.save!
        special_verification2 = SpecialVerification.new(due_date: TimeKeeper.date_of_record.next_month, verification_type: "Social Security Number", type: "notice")
        person2.consumer_role.special_verifications << special_verification2
        person2.consumer_role.save!
        @eligibility_notice.build
        expect(@eligibility_notice.notice.due_date).to eq special_verification2.due_date
      end

      it "should return nil when no future dates are present" do
        special_verification = SpecialVerification.new(due_date: TimeKeeper.date_of_record.prev_day, verification_type: "Social Security Number", type: "notice")
        person.consumer_role.special_verifications << special_verification
        person.consumer_role.save!
        special_verification2 = SpecialVerification.new(due_date: TimeKeeper.date_of_record.prev_month, verification_type: "Social Security Number", type: "notice")
        person2.consumer_role.special_verifications << special_verification2
        person2.consumer_role.save!
        @eligibility_notice.build
        expect(@eligibility_notice.notice.due_date).to eq nil
      end
    end

    context "when there are no outstanding verification family members" do
      let(:payload) { "somepayload" }
      it "should return nil" do
        args = OpenStruct.new
        args.determined_at = TimeKeeper.datetime_of_record - 1.month
        args.vlp_authority = "ssa"
        person.consumer_role.lawful_presence_determination.vlp_responses << EventResponse.new({received_at: args.determined_at, body: payload})
        person.consumer_role.coverage_purchased!
        person.consumer_role.ssn_valid_citizenship_invalid!(args)
        @eligibility_notice.build
        expect(@eligibility_notice.min_notice_due_date(family)).to eq nil
      end
    end
  end

  describe "#attach_required_documents" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EnrollmentNoticeBuilderWithDateRange.new(person.consumer_role, valid_params)
    end

    it "should render not documents section when the family came in through curam(Assisted)" do
      @eligibility_notice.append_hbe
      @eligibility_notice.build
      expect(@eligibility_notice).not_to receive :attach_required_documents
      @eligibility_notice.attach_docs
    end

    it "should render documents section when the family has an invalid e_case_id and outstanding people are present" do
      family.update_attributes!(:e_case_id => "curam_landing_for10000")
      @eligibility_notice.append_hbe
      @eligibility_notice.build
      expect(@eligibility_notice).to receive :attach_required_documents
      @eligibility_notice.attach_docs
    end

    it "should render documents section when the family is unassisted and outstanding people are present" do
      family.update_attributes!(:e_case_id => nil)
      @eligibility_notice.append_hbe
      @eligibility_notice.build
      expect(@eligibility_notice).to receive :attach_required_documents
      @eligibility_notice.attach_docs
    end

    it "should not render documents when no outstanding people" do
      allow(person.consumer_role).to receive_message_chain("outstanding_verification_types").and_return(nil)
      expect(@eligibility_notice).not_to receive :attach_required_documents
      @eligibility_notice.attach_docs
    end
  end

  describe "render template and generate pdf" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EnrollmentNoticeBuilderWithDateRange.new(person.consumer_role, valid_params)
    end

    it "should render environment_notice" do
      expect(@eligibility_notice.template).to eq "notices/ivl/enrollment_notice"
    end

    it "should generate pdf" do
      @eligibility_notice.append_hbe
      bc_period = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
      @eligibility_notice.build
      file = @eligibility_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

end
end
