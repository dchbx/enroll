require 'rails_helper'

RSpec.describe IvlNotices::ReminderNotice, :dbclean => :after_each do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person, :min_verification_due_date => TimeKeeper.date_of_record+95.days) }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.month - 1.year}
  let(:hbx_enrollment_member){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, hbx_enrollment_members: [hbx_enrollment_member], household: family.active_household, kind: "individual", aasm_state: "enrolled_contingent")}
  let(:plan){ FactoryGirl.create(:plan) }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'First Outstanding Verification Notification',
                            :notice_template => 'notices/ivl/documents_verification_reminder',
                            :notice_builder => 'IvlNotices::ReminderNotice',
                            :mpi_indicator => 'MPI_IVLV20A',
                            :event_name => 'first_verifications_reminder',
                            :title => "First Outstanding Verification Notification"})
                          }
    let(:valid_parmas) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template
    }}

  describe "New" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(hbx_enrollment).to receive("plan").and_return(plan)
      person.consumer_role.update_attributes!(:aasm_state => "verification_outstanding")
      @consumer_role = IvlNotices::ReminderNotice.new(person.consumer_role, valid_parmas)
    end
    context "valid params" do
      it "should initialze" do
        @consumer_role = IvlNotices::ReminderNotice.new(person.consumer_role, valid_parmas)
        expect{IvlNotices::ReminderNotice.new(person.consumer_role, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{IvlNotices::ReminderNotice.new(person.consumer_role, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      person.consumer_role.update_attributes!(:aasm_state => "verification_outstanding")
      allow(hbx_enrollment).to receive("plan").and_return(plan)
      allow(person).to receive("primary_family").and_return(family)
      @reminder_notice = IvlNotices::ReminderNotice.new(person.consumer_role, valid_parmas)
      @reminder_notice.build
    end
    it "should retun priamry full name" do
      expect(@reminder_notice.notice.primary_fullname).to eq person.full_name.titleize
    end
    it "should retun notification type" do
      expect(@reminder_notice.notice.notification_type).to eq application_event.event_name
    end
  end

  describe "#document_due_date", dbclean: :after_each do
    context "when special verifications exists" do
      let(:special_verification) { FactoryGirl.create(:special_verification, type: "admin")}
      let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: special_verification.consumer_role.person)}

      it "should return the due date on the related latest special verification" do
        expect(family.document_due_date(family.primary_family_member, special_verification.verification_type)).to eq special_verification.due_date.to_date
      end
    end

    context "when special verifications not exist" do

      let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
      let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}

      context "when the family member had an 'enrolled_contingent' policy" do

        let(:enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, household: family.active_household, aasm_state: "enrolled_contingent")}

        before do
          fm = family.primary_family_member
          enrollment.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: fm.id, is_subscriber: fm.is_primary_applicant, eligibility_date: TimeKeeper.date_of_record , coverage_start_on: TimeKeeper.date_of_record)
        end

        #No longer updating special_verification_period on erollment. Due dates are moved to member level.
        it "should return nil if special_verification_period on the enrollment is nil" do
          enrollment.special_verification_period = nil
          enrollment.save
          expect(family.document_due_date(family.primary_family_member, "Citizenship")).to eq nil
        end
      end

      context "when the family member had no policy" do
        it "should return nil" do
          expect(family.document_due_date(family.primary_family_member, "Citizenship")).to eq nil
        end
      end
    end
  end


  describe "#append_notice_subject" do
    before do
      person.consumer_role.update_attributes!(:aasm_state => "verification_outstanding")
      allow(hbx_enrollment).to receive("plan").and_return(plan)
      allow(person).to receive("primary_family").and_return(family)
      @reminder_notice = IvlNotices::ReminderNotice.new(person.consumer_role, valid_parmas)
      @reminder_notice.build
    end
    it "should retun priamry full name" do
      expect(@reminder_notice.notice.notice_subject).to eq "REMINDER - KEEPING YOUR INSURANCE - SUBMIT DOCUMENTS BY #{@reminder_notice.notice.due_date.strftime("%^B %d, %Y")}"
    end
  end

  describe "#generate_pdf_notice" do
    before do
      person.consumer_role.update_attributes!(:aasm_state => "verification_outstanding")
      allow(hbx_enrollment).to receive("plan").and_return(plan)
      allow(person).to receive("primary_family").and_return(family)
      @reminder_notice = IvlNotices::ReminderNotice.new(person.consumer_role, valid_parmas)
    end

    it "should render the projected eligibility notice template" do
      expect(@reminder_notice.template).to eq "notices/ivl/documents_verification_reminder"
    end

    it "should generate pdf" do
      @reminder_notice.build
      file = @reminder_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

  describe "append_unverified_individuals" do

    before :each do
      person.consumer_role.update_attributes!(:aasm_state => "verification_outstanding")
      allow(hbx_enrollment).to receive("plan").and_return(plan)
      allow(person).to receive("primary_family").and_return(family)
      @reminder_notice = IvlNotices::ReminderNotice.new(person.consumer_role, valid_parmas)
    end

    context "immigration" do
      before :each do
        allow(person).to receive(:verification_types).and_return(['Immigration status'])
      end

      it "should have immigration pdf template" do
        @reminder_notice.build
        expect(@reminder_notice.notice.immigration_unverified.present?).to be_truthy
      end

      it "should not return citizenship pdf template if person is outstanding due to immigration" do
        @reminder_notice.build
        expect(@reminder_notice.notice.dhs_unverified.present?).to be_falsey
      end
    end

    context "citizenship" do
      before :each do
        allow(person).to receive(:verification_types).and_return(['Citizenship'])
        allow(person.consumer_role).to receive(:outstanding_verification_types).and_return(['Citizenship'])
      end

      it "should have citizenship pdf template" do
        person.consumer_role.update_attributes!(citizen_status: "us_citizen")
        @reminder_notice.build
        expect(@reminder_notice.notice.dhs_unverified.present?).to be_truthy
      end

      it "should not return immigration pdf template if person is outstanding due to citizenship" do
        @reminder_notice.build
        expect(@reminder_notice.notice.immigration_unverified.present?).to be_falsey
      end
    end

    context "both citizenship and immigration" do

      before :each do
        allow(person).to receive(:verification_types).and_return(['Citizenship', 'Immigration status'])
        allow(person.consumer_role).to receive(:outstanding_verification_types).and_return(['Citizenship', 'Immigration status'])
      end

      it "should return immigration pdf template and  citizenship pdf template" do
        person.consumer_role.update_attributes!(citizen_status: "us_citizen")
        @reminder_notice.build
        expect(@reminder_notice.notice.dhs_unverified.present?).to be_truthy
        expect(@reminder_notice.notice.immigration_unverified.present?).to be_truthy
      end

      it "should not return any other pdf templates" do
        @reminder_notice.build
        expect(@reminder_notice.notice.american_indian_unverified.present?).to be_falsey
        expect(@reminder_notice.notice.residency_inconsistency.present?).to be_falsey
        expect(@reminder_notice.notice.ssa_unverified.present?).to be_falsey
      end
    end
  end
end