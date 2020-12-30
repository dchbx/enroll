require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe IvlNotices::EnrollmentNoticeBuilder, dbclean: :after_each do
  let(:person) { FactoryBot.create(:person)}
  let!(:consumer_role) { FactoryBot.create(:consumer_role, person: person) }
  let(:min_verification_due_date) { TimeKeeper.date_of_record + 10.days }
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person, e_case_id: "family_test#1000", min_verification_due_date: min_verification_due_date)}
  let(:issuer_profile) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
  let!(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01', issuer_profile: issuer_profile)}
  let(:hbx_enrollment_members) { [hbx_enrollment_member] }
  let!(:hbx_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      created_at: (TimeKeeper.date_of_record.in_time_zone("Eastern Time (US & Canada)") - 2.days),
      family: family,
      household: family.households.first,
      hbx_enrollment_members: hbx_enrollment_members,
      kind: "individual",
      is_any_enrollment_member_outstanding: true,
      aasm_state: 'coverage_selected',
      product: product
    )
  end
  let!(:hbx_enrollment_member) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month) }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Enrollment Notice',
                            :notice_template => 'notices/ivl/enrollment_notice',
                            :notice_builder => 'IvlNotices::EnrollmentNoticeBuilder',
                            :event_name => 'enrollment_notice',
                            :mpi_indicator => 'IVL_ENR',
                            :title => "Enrollment notice"})
                          }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}
  let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }
  let(:citizenship_type) { FactoryBot.build(:verification_type, type_name: 'Citizenship')}
  let(:ssn_type) { FactoryBot.build(:verification_type, type_name: 'Social Security Number')}

  after(:each) do
    DatabaseCleaner.clean
  end

  describe "New" do
    before do
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::EnrollmentNoticeBuilder.new(person.consumer_role, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{IvlNotices::EnrollmentNoticeBuilder.new(person.consumer_role, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before :each do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive(:families).and_return([family])
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EnrollmentNoticeBuilder.new(person.consumer_role, valid_params)
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
      expect(@eligibility_notice.notice.enrollments.first.plan.plan_name).to eq hbx_enrollment.product.title
    end
    it "should retun carrier name" do
      expect(@eligibility_notice.notice.enrollments.first.plan.plan_carrier).to eq hbx_enrollment.product.issuer_profile.organization.legal_name
    end
    it "should return plan deductible" do
      expect(@eligibility_notice.notice.enrollments.first.plan.deductible).to eq hbx_enrollment.product.deductible
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
      allow(person).to receive(:families).and_return([family])
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EnrollmentNoticeBuilder.new(person.consumer_role, valid_params)
    end
    context "when special verification already exists" do
      let (:citizenship_type) { FactoryBot.build(:verification_type, type_name: 'Citizenship', due_date: Date.new(2017,5,5), due_date_type: 'notice')}

      it "should not update the due date" do
        person.consumer_role.verification_types.by_name('Citizenship').first.due_date = citizenship_type.due_date
        person.consumer_role.verification_types.by_name('Citizenship').first.due_date_type = citizenship_type.due_date_type
        person.consumer_role.save!
        @eligibility_notice.build
        expect(@eligibility_notice.document_due_date(person, citizenship_type)).to eq citizenship_type.due_date
      end
    end
    context "when special verification does not exist" do
      let (:ssn_type) { FactoryBot.build(:verification_type, type_name: 'Social Security Number', due_date: (Date.today + 95.days), due_date_type: 'notice')}
      it "should update the due date" do
        person.consumer_role.verification_types.by_name('Social Security Number').first.due_date = ssn_type.due_date
        person.consumer_role.verification_types.by_name('Social Security Number').first.due_date_type = ssn_type.due_date_type
        person.consumer_role.save!
        @eligibility_notice.build
        expect(@eligibility_notice.document_due_date(person, ssn_type)).to eq (TimeKeeper.date_of_record+Settings.aca.individual_market.verification_due.days)
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
        expect(@eligibility_notice.document_due_date(person, ssn_type)).to eq nil
      end
    end
  end

  describe "min_notice_due_date", dbclean: :after_each do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive(:families).and_return([family])
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EnrollmentNoticeBuilder.new(person.consumer_role, valid_params)
    end

    context "when there are outstanding verification family members" do
      let!(:person2) { FactoryBot.create(:person, :with_consumer_role)}
      let!(:family_member2) { FactoryBot.create(:family_member, family: family, is_active: true, person: person2) }
      let!(:hbx_enrollment_member2) {FactoryBot.build(:hbx_enrollment_member, applicant_id: family_member2.id, eligibility_date: TimeKeeper.date_of_record.prev_month)}
      let(:hbx_enrollment_members) { [hbx_enrollment_member, hbx_enrollment_member2] }
      let(:due_date) { family.min_verification_due_date.present? && family.min_verification_due_date > TimeKeeper.date_of_record ? family.min_verification_due_date : @eligibility_notice.min_notice_due_date(family) }

      it "should return a future date when present" do
        person.consumer_role.save!
        person2.consumer_role.save!
        @eligibility_notice.build
        expect(@eligibility_notice.notice.due_date).to eq due_date
      end

      context 'when no future dates are present' do
        let(:min_verification_due_date) { nil }

        it "should return nil " do
          allow(family).to receive(:contingent_enrolled_active_family_members).and_return([])
          person.consumer_role.save!
          person2.consumer_role.save!
          @eligibility_notice.build
          expect(@eligibility_notice.notice.due_date).to eq nil
        end
      end
    end

    context "when there are no outstanding verification family members" do
      let(:payload) { "somepayload" }
      it "should return nil" do
        allow(family).to receive(:contingent_enrolled_active_family_members).and_return([])
        args = OpenStruct.new
        args.determined_at = TimeKeeper.datetime_of_record - 1.month
        args.vlp_authority = "ssa"
        person.consumer_role.update_attributes(aasm_state: 'unverified')
        person.consumer_role.lawful_presence_determination.vlp_responses << EventResponse.new({received_at: args.determined_at, body: payload})
        person.consumer_role.coverage_purchased!
        person.consumer_role.ssn_valid_citizenship_valid!(args)
        @eligibility_notice.build
        expect(@eligibility_notice.min_notice_due_date(family)).to eq nil
      end
    end
  end

  describe "#attach_required_documents" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive(:families).and_return([family])
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EnrollmentNoticeBuilder.new(person.consumer_role, valid_params)
    end

    it "should render documents section when the family came in through curam(Assisted)" do
      @eligibility_notice.append_hbe
      @eligibility_notice.build
      expect(@eligibility_notice).to receive :attach_required_documents
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
      person.consumer_role.update_attributes(aasm_state: 'verification_outstanding')
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive(:families).and_return([family])
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @eligibility_notice = IvlNotices::EnrollmentNoticeBuilder.new(person.consumer_role, valid_params)
    end

    it "should render environment_notice" do
      expect(@eligibility_notice.template).to eq "notices/ivl/enrollment_notice"
    end

    it "should generate pdf" do
      @eligibility_notice.append_hbe
      @eligibility_notice.build
      file = @eligibility_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end

    it "should delete generated pdf" do
      @eligibility_notice.append_hbe
      @eligibility_notice.build
      file = @eligibility_notice.generate_pdf_notice
      @eligibility_notice.clear_tmp(file.path)
      expect(File.exist?(file.path)).to be false
    end
  end
end
end
