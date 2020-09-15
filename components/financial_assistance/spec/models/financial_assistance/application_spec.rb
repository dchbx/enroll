# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'

RSpec.describe ::FinancialAssistance::Application, type: :model, dbclean: :after_each do

  let(:family_id) { BSON::ObjectId.new }
  let!(:year) { TimeKeeper.date_of_record.year }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id) }
  let!(:eligibility_determination1) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:eligibility_determination2) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:eligibility_determination3) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:application2) { FactoryBot.create(:financial_assistance_application, family_id: family_id, assistance_year: TimeKeeper.date_of_record.year, aasm_state: 'denied') }
  let!(:application3) { FactoryBot.create(:financial_assistance_application, family_id: family_id, assistance_year: TimeKeeper.date_of_record.year, aasm_state: 'determination_response_error') }
  let!(:application4) { FactoryBot.create(:financial_assistance_application, family_id: family_id, assistance_year: TimeKeeper.date_of_record.year, aasm_state: 'determined') }
  let!(:application5) { FactoryBot.create(:financial_assistance_application, family_id: family_id, assistance_year: TimeKeeper.date_of_record.year, aasm_state: 'determined') }
  let!(:applicant1) { FactoryBot.create(:financial_assistance_applicant, eligibility_determination_id: eligibility_determination1.id, application: application, family_member_id: BSON::ObjectId.new) }
  let!(:applicant2) { FactoryBot.create(:financial_assistance_applicant, eligibility_determination_id: eligibility_determination2.id, application: application, family_member_id: BSON::ObjectId.new) }
  let!(:applicant3) { FactoryBot.create(:financial_assistance_applicant, eligibility_determination_id: eligibility_determination3.id, application: application, family_member_id: BSON::ObjectId.new) }

  describe '.modelFeilds' do
    it { is_expected.to have_field(:hbx_id).of_type(String) }
    it { is_expected.to have_field(:external_id).of_type(String) }
    it { is_expected.to have_field(:integrated_case_id).of_type(String) }
    it { is_expected.to have_field(:haven_app_id).of_type(String) }
    it { is_expected.to have_field(:haven_ic_id).of_type(String) }
    it { is_expected.to have_field(:e_case_id).of_type(String) }
    it { is_expected.to have_field(:applicant_kind).of_type(String) }
    it { is_expected.to have_field(:request_kind).of_type(String) }
    it { is_expected.to have_field(:motivation_kind).of_type(String) }
    it { is_expected.to have_field(:is_joint_tax_filing).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:eligibility_determination_id).of_type(BSON::ObjectId) }
    it { is_expected.to have_field(:aasm_state).of_type(String).with_default_value_of(:draft) }
    it { is_expected.to have_field(:submitted_at).of_type(DateTime) }
    it { is_expected.to have_field(:effective_date).of_type(DateTime) }
    it { is_expected.to have_field(:timeout_response_last_submitted_at).of_type(DateTime) }
    it { is_expected.to have_field(:assistance_year).of_type(Integer) }
    it { is_expected.to have_field(:is_renewal_authorized).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:renewal_base_year).of_type(Integer) }
    it { is_expected.to have_field(:years_to_renew).of_type(Integer) }
    it { is_expected.to have_field(:is_requesting_voter_registration_application_in_mail).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:us_state).of_type(String) }
    it { is_expected.to have_field(:medicaid_terms).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:medicaid_insurance_collection_terms).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:report_change_terms).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:parent_living_out_of_home_terms).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:attestation_terms).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:submission_terms).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:request_full_determination).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:is_ridp_verified).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:determination_http_status_code).of_type(Integer) }
    it { is_expected.to have_field(:determination_error_message).of_type(String) }
    it { is_expected.to have_field(:has_eligibility_response).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:workflow).of_type(Hash).with_default_value_of({}) }
  end

  describe '.Validations' do
    subject { application }

    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it 'is not valid without a hbx_id' do
      subject.hbx_id = nil
      expect(subject).to_not be_valid(:submission)
    end

    it 'is not valid without an applicant_kind' do
      subject.applicant_kind = nil
      expect(subject).to_not be_valid(:submission)
    end
  end

  describe '.Associations' do
    it 'embeds many applicants' do
      assc = described_class.reflect_on_association(:applicants)
      expect(assc.class).to eq Mongoid::Association::Embedded::EmbedsMany
    end

    it 'embeds many workflow_state_transitions' do
      assc = described_class.reflect_on_association(:workflow_state_transitions)
      expect(assc.class).to eq Mongoid::Association::Embedded::EmbedsMany
    end
  end

  describe '.Constants' do
    let(:class_constants)  { subject.class.constants }

    it 'should have years to renew range constant' do
      expect(class_constants.include?(:YEARS_TO_RENEW_RANGE)).to be_truthy
      expect(described_class::YEARS_TO_RENEW_RANGE).to eq(0..5)
    end

    it 'should have renewal basse year range constant' do
      expect(class_constants.include?(:RENEWAL_BASE_YEAR_RANGE)).to be_truthy
      expect(described_class::RENEWAL_BASE_YEAR_RANGE).to eq(2013..TimeKeeper.date_of_record.year + 1)
    end

    it 'should have applicant kinds constant' do
      expect(class_constants.include?(:APPLICANT_KINDS)).to be_truthy
      expect(described_class::APPLICANT_KINDS).to eq(['user and/or family', 'call center rep or case worker', 'authorized representative'])
    end

    it 'should have source kinds constant' do
      expect(class_constants.include?(:SOURCE_KINDS)).to be_truthy
      expect(described_class::SOURCE_KINDS).to eq(%w[paper source in-person])
    end

    it 'should have request kinds constant' do
      expect(class_constants.include?(:REQUEST_KINDS)).to be_truthy
      expect(described_class::REQUEST_KINDS).to eq(%w[])
    end

    it 'should have motivation kinds constant' do
      expect(class_constants.include?(:MOTIVATION_KINDS)).to be_truthy
      expect(described_class::MOTIVATION_KINDS).to eq(%w[insurance_affordability])
    end

    it 'should have submitted status constant' do
      expect(class_constants.include?(:SUBMITTED_STATUS)).to be_truthy
      expect(described_class::SUBMITTED_STATUS).to eq(%w[submitted verifying_income])
    end
  end

  describe '.Scopes' do
    it 'should not return draft applications' do
      expect(FinancialAssistance::Application.all.for_verifications.map(&:aasm_state)).not_to include 'draft'
      expect(FinancialAssistance::Application.all.for_verifications.map(&:aasm_state)).to include 'determined'
    end
  end

  describe '.compute_actual_days_worked' do
    it 'returns actual working days between start_date and end_date' do
      start_date = Date.new(year, 2, 14)
      end_date = Date.new(year, 9, 23)
      expect(application.compute_actual_days_worked(year, start_date, end_date)).to eq 158
    end
  end

  describe '.has_accepted_medicaid_terms?' do
    it 'returns true if includes SUBMITTED_STATUS' do
      application.update_attributes(aasm_state: 'submitted')
      application.send(:has_accepted_medicaid_terms?)
      expect(described_class::SUBMITTED_STATUS.include?(application.aasm_state)).to eq(true)
    end
    it 'returns false if do not include SUBMITTED_STATUS' do
      application.update_attributes(aasm_state: 'determined')
      application.send(:has_accepted_medicaid_terms?)
      expect(described_class::SUBMITTED_STATUS.include?(application.aasm_state)).to eq(false)
    end
  end

  describe '.has_accepted_attestation_terms?' do
    it 'returns true if includes SUBMITTED_STATUS' do
      application.update_attributes(aasm_state: 'submitted')
      application.send(:has_accepted_attestation_terms?)
      expect(described_class::SUBMITTED_STATUS.include?(application.aasm_state)).to eq(true)
    end
    it 'returns false if do not include SUBMITTED_STATUS' do
      application.update_attributes(aasm_state: 'determined')
      application.send(:has_accepted_attestation_terms?)
      expect(described_class::SUBMITTED_STATUS.include?(application.aasm_state)).to eq(false)
    end
  end

  describe '.has_accepted_submission_terms?' do
    it 'returns true if includes SUBMITTED_STATUS' do
      application.update_attributes(aasm_state: 'submitted')
      application.send(:has_accepted_submission_terms?)
      expect(described_class::SUBMITTED_STATUS.include?(application.aasm_state)).to eq(true)
    end
    it 'returns false if do not include SUBMITTED_STATUS' do
      application.update_attributes(aasm_state: 'determined')
      application.send(:has_accepted_submission_terms?)
      expect(described_class::SUBMITTED_STATUS.include?(application.aasm_state)).to eq(false)
    end
  end

  describe '.primary_applicant' do
    it 'returns primary_applicant' do
      primary_applicant = application.active_applicants.detect(&:is_primary_applicant?)
      expect(application.primary_applicant).to eq(primary_applicant)
    end
  end

  describe '.populate_applicants_for?' do
    it 'returns populated applicants for family member' do
      application.applicants.all.destroy
      expect(application.tap(&:import_applicants).applicants).to eq(application.applicants)
    end
  end

  describe '.current_csr_percent_as_integer' do
    it 'should return current csr percent' do
      application.eligibility_determination_for(eligibility_determination1.id)
      expect(application.current_csr_percent_as_integer(eligibility_determination1.id)).to eq(eligibility_determination1.csr_percent_as_integer)
    end

    it 'should return right eligibility_determination' do
      ed = application.eligibility_determinations[0]
      expect(ed).to eq eligibility_determination1
    end
  end

  describe '.complete?' do
    it 'should returns true if application is valid and complete' do
      allow(application).to receive(:is_application_valid?).and_return(true)
      expect(application.complete?).to be_truthy
    end
    it 'should returns false if application is not valid' do
      allow(application).to receive(:is_application_valid?).and_return(false)
      expect(application.complete?).to be_falsey
    end
  end

  describe '.is_submitted?' do
    it 'should returns true if aasm state is submitted' do
      application.update_attributes(aasm_state: 'submitted')
      expect(application.is_submitted?).to be_truthy
    end

    it 'should returns aasm state as submitted' do
      application.update_attributes(aasm_state: 'submitted')
      expect(application.aasm_state).to include('submitted')
    end

    it 'should return false if aasm state is not submitted' do
      expect(application.is_submitted?).to be_falsey
    end

    it 'should not return aasm state as submitted' do
      expect(application.aasm_state).not_to include('submitted')
    end
  end

  describe '.ready_for_attestation?' do
    let!(:valid_application) do
      FactoryBot.create(
        :financial_assistance_application,
        family_id: BSON::ObjectId.new,
        hbx_id: '345332',
        applicant_kind: 'user and/or family',
        request_kind: 'request-kind',
        motivation_kind: 'motivation-kind',
        us_state: 'DC',
        is_ridp_verified: true,
        assistance_year: TimeKeeper.date_of_record.year,
        aasm_state: 'draft',
        medicaid_terms: true,
        attestation_terms: true,
        submission_terms: true,
        medicaid_insurance_collection_terms: true,
        report_change_terms: true,
        parent_living_out_of_home_terms: true,
        applicants: [applicant_primary]
      )
    end
    let!(:applicant_primary) do
      FactoryBot.create(:applicant, eligibility_determination_id: eligibility_determination1.id, application: application, family_member_id: family_member_id)
    end
    let(:family_member_id) { BSON::ObjectId.new }

    it 'should returns true if application is ready_for_attestation' do
      allow(applicant_primary).to receive(:applicant_validation_complete?).and_return(true)
      allow(valid_application).to receive(:relationships_complete?).and_return(true)
      expect(valid_application.ready_for_attestation?).to be_truthy
    end

    it 'should returns false if application is not ready_for_attestation' do
      expect(valid_application.ready_for_attestation?).to be_falsey
    end
  end

  describe '.incomplete_applicants?' do
    it 'should returns true if application has incomplete_applicants' do
      allow(applicant1).to receive(:applicant_validation_complete?).and_return(false)
      application.incomplete_applicants?
      expect(application.incomplete_applicants?).to be_truthy
    end

    it 'should returns false if application has no incomplete_applicants' do
      expect(application.ready_for_attestation?).to be_falsey
    end
  end

  describe '.next_incomplete_applicant' do
    it 'returns applicant primary if application has next_incomplete_applicant' do
      allow(applicant1).to receive(:applicant_validation_complete?).and_return(false)
      expect(application.next_incomplete_applicant).to eq applicant1
    end
  end

  describe '.active_applicants' do
    it 'returns active_applicants for a given application' do
      expect(application.active_applicants).to eq application.applicants.where(:is_active => true)
    end
  end

  describe '.is_draft?' do
    it 'should returns true if aasm state is draft' do
      application.update_attributes(aasm_state: 'draft')
      expect(application.is_draft?).to be_truthy
    end

    it 'should returns aasm state draft' do
      application.update_attributes(aasm_state: 'draft')
      expect(application.aasm_state).to include('draft')
    end

    it 'should return false if aasm state is not draft' do
      application.update_attributes(aasm_state: 'determined')
      expect(application.is_draft?).to be_falsey
    end

    it 'should not return aasm state as draft' do
      application.update_attributes(aasm_state: 'determined')
      expect(application.aasm_state).not_to include('draft')
    end
  end

  describe '.is_determined?' do
    it 'should returns true if aasm state is determined' do
      application.update_attributes(aasm_state: 'determined')
      expect(application.is_determined?).to be_truthy
    end

    it 'should returns aasm state as determined' do
      application.update_attributes(aasm_state: 'determined')
      expect(application.aasm_state).to include('determined')
    end

    it 'should return false if aasm state is not determined' do
      application.update_attributes(aasm_state: 'draft')
      expect(application.is_determined?).to be_falsey
    end

    it 'should not return aasm state as determined' do
      application.update_attributes(aasm_state: 'draft')
      expect(application.aasm_state).not_to include('determined')
    end
  end

  describe '.set_assistance_year' do
    let(:assistance_year) { TimeKeeper.date_of_record + 1.year}
    let(:family_id)       { BSON::ObjectId.new }      
    let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id) }
    it 'updates assistance year' do
      application.send(:set_assistance_year)
      expect(application.assistance_year).to eq(assistance_year.year - 1)
    end
  end

  describe '.eligibility_determinations' do
    it 'verifies eligibility_determinations count of a given applicant' do
      expect(application.eligibility_determinations.count).to eq 3
    end
  end

  describe 'trigger eligibility notice' do
    let!(:applicant) { FactoryBot.create(:applicant, eligibility_determination_id: eligibility_determination1.id, application: application, family_member_id: BSON::ObjectId.new) }
    before do
      application.update_attributes(:aasm_state => 'submitted')
    end

    it 'on event determine and family totally eligibile' do
      expect(application.is_family_totally_ineligibile).to be_falsey
      application.determine!
    end
  end

  describe 'trigger ineligibilility notice' do
    let(:family_member_id) { BSON::ObjectId.new }
    let!(:applicant) { FactoryBot.create(:applicant, eligibility_determination_id: eligibility_determination1.id, application: application, family_member_id: family_member_id) }
    before do
      application.active_applicants.each do |applicant|
        applicant.is_totally_ineligible = true
        applicant.save!
      end
      application.update_attributes(:aasm_state => 'submitted')
    end

    it 'event determine and family totally ineligibile' do
      expect(application.is_family_totally_ineligibile).to be_truthy
      application.determine!
    end
  end

  describe 'generates hbx_id for application' do
    let(:new_family_id) { BSON::ObjectId.new }
    let(:new_application) { FactoryBot.build(:financial_assistance_application, family_id: new_family_id) }

    it 'creates an hbx id if do not exists' do
      expect(new_application.hbx_id).to eq nil
      new_application.save
      expect(new_application.hbx_id).not_to eq nil
    end
  end

  describe 'for create_eligibility_determinations' do
    before :each do
      application.update_attributes(family_id: family_id, hbx_id: '345334', applicant_kind: 'user and/or family', request_kind: 'request-kind',
                                    motivation_kind: 'motivation-kind', us_state: 'DC', is_ridp_verified: true, assistance_year: TimeKeeper.date_of_record.year, aasm_state: 'draft',
                                    medicaid_terms: true, attestation_terms: true, submission_terms: true, medicaid_insurance_collection_terms: true,
                                    report_change_terms: true, parent_living_out_of_home_terms: true)
      allow(application).to receive(:is_application_valid?).and_return(true)
    end

    it 'When there are two joint filers and one claimed as tax dependent - applicants looping order 1' do
      applicant1.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: true, is_required_to_file_taxes: true)
      applicant2.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant1.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      applicant3.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: true, is_required_to_file_taxes: true)
      application.submit!
      expect(applicant1.tax_filer_kind).to eq 'tax_filer'
      expect(applicant2.tax_filer_kind).to eq 'dependent'
      expect(applicant3.tax_filer_kind).to eq 'tax_filer'
    end

    it 'When there is one tax filers and two claimed as tax dependent - applicants looping order 2' do
      applicant1.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant3.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      applicant2.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant3.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      applicant3.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: true)
      application.submit!
      expect(applicant1.tax_filer_kind).to eq 'dependent'
      expect(applicant2.tax_filer_kind).to eq 'dependent'
      expect(applicant3.tax_filer_kind).to eq 'tax_filer'
    end

    it 'When there is one tax filers and two claimed as tax dependent - applicants looping order 3' do
      applicant1.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: true)
      applicant2.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant1.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      applicant3.update_attributes(is_claimed_as_tax_dependent: false, claimed_as_tax_dependent_by: nil, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      application.submit!
      expect(applicant1.tax_filer_kind).to eq 'tax_filer'
      expect(applicant2.tax_filer_kind).to eq 'dependent'
      expect(applicant3.tax_filer_kind).to eq 'non_filer'
    end

    it 'When there are two tax filers and one claimed as tax dependent - applicants looping order 4' do
      applicant1.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: true)
      applicant2.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: true)
      applicant3.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant1.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      application.submit!
      expect(applicant1.tax_filer_kind).to eq 'tax_filer'
      expect(applicant2.tax_filer_kind).to eq 'tax_filer'
      expect(applicant3.tax_filer_kind).to eq 'dependent'
    end
  end

  describe 'applications with eligibility determinations, tax households and applicants' do
    it 'should return all the eligibility determinations of the application' do
      application.update_attributes(assistance_year: year)
      expect(application.eligibility_determinations_for_year(year).size).to eq 3
      application.eligibility_determinations_for_year(year).each do |ed|
        expect(application.eligibility_determinations_for_year(year)).to include(ed)
      end
    end

    it 'should return all the eligibility determinations of the application' do
      expect(application.eligibility_determinations.count).to eq 3
      expect(application.eligibility_determinations).to eq [eligibility_determination1, eligibility_determination2, eligibility_determination3]
    end

    it 'should not return wrong number of eligibility determinations of the application' do
      expect(application.eligibility_determinations.count).not_to eq 4
      expect(application.eligibility_determinations).not_to eq [eligibility_determination1, eligibility_determination2]
    end

    it 'should return the latest eligibility determinations' do
      eligibility_determination1.update_attributes('effective_starting_on' => Date.new(year,1,1), is_eligibility_determined: true)
      eligibility_determination2.update_attributes('effective_starting_on' => Date.new(year,1,1), is_eligibility_determined: true)
      expect(application.latest_active_eligibility_determinations_with_year(year).count).to eq 2
      expect(application.latest_active_eligibility_determinations_with_year(year)).to eq [eligibility_determination1, eligibility_determination2]
    end

    it 'should only return latest eligibility_determinations of application' do
      expect(application.latest_active_eligibility_determinations_with_year(year).count).not_to eq 3
      expect(application.latest_active_eligibility_determinations_with_year(year)).not_to eq [eligibility_determination1, eligibility_determination2, eligibility_determination3]
    end

    it 'should match correct eligibility' do
      expect(application.eligibility_determinations[0]).to eq eligibility_determination1
      expect(application.eligibility_determinations[1]).to eq eligibility_determination2
      expect(application.eligibility_determinations[2]).to eq eligibility_determination3
    end

    it 'should not return wrong eligibility determinations' do
      application.update_attributes(assistance_year: year)
      expect(application.eligibility_determinations_for_year(year).size).not_to eq 1
      ed1 = application.eligibility_determinations[0]
      expect(ed1).not_to eq eligibility_determination3
    end

    it 'should return unique eligibility determinations with active_approved_application applicants' do
      expect(application.eligibility_determinations.count).to eq 3
      expect(application.eligibility_determinations).to eq [eligibility_determination1, eligibility_determination2, eligibility_determination3]
    end

    it 'should not return all eligibility_determinations' do
      expect(application.eligibility_determinations).not_to eq applicant1.eligibility_determination.to_a
    end
  end

  context 'is_reviewable?' do
    let(:faa) { double(:application) }
    context 'when submitted' do
      it 'should return true' do
        allow(application).to receive(:aasm_state).and_return('submitted')
        expect(application.is_reviewable?).to eq true
      end
    end

    context 'when determination_response_error' do
      it 'should return true' do
        allow(application).to receive(:aasm_state).and_return('determination_response_error')
        expect(application.is_reviewable?).to eq true
      end
    end

    context 'when determined' do
      it 'should return true' do
        allow(application).to receive(:aasm_state).and_return('determined')
        expect(application.is_reviewable?).to eq true
      end
    end

    it 'should return false if the application is in draft state' do
      allow(application).to receive(:aasm_state).and_return('draft')
      expect(application.is_reviewable?).to eq false
    end
  end

  describe 'check the validity of an application' do

    let!(:valid_app) { FactoryBot.create(:financial_assistance_application, aasm_state: 'draft', family_id: family_id) }
    let!(:invalid_app) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: 'draft') }
    let!(:applicant_primary) { FactoryBot.create(:applicant, eligibility_determination_id: ed1.id, application: valid_app) }
    let!(:applicant_primary2) { FactoryBot.create(:applicant, eligibility_determination_id: ed2.id, application: invalid_app) }
    let!(:ed1) { FactoryBot.create(:financial_assistance_eligibility_determination, application: valid_app) }
    let!(:ed2) { FactoryBot.create(:financial_assistance_eligibility_determination, application: invalid_app) }

    it 'should allow a sucessful state transition for valid application' do
      allow(valid_app).to receive(:is_application_valid?).and_return(true)
      expect(valid_app.submit).to be_truthy
      expect(valid_app.determine).to be_truthy
      expect(valid_app.aasm_state).to eq 'determined'
    end

    it 'should prevent state transition for invalid application' do
      invalid_app.update_attributes!(hbx_id: nil)
      expect(invalid_app).to receive(:report_invalid)
      invalid_app.submit!
      expect(invalid_app.aasm_state).to eq 'draft'
    end

    it 'should invoke submit_application on a submit of an valid application' do
      allow(valid_app).to receive(:is_application_valid?).and_return(true)
      valid_app.submit!
    end

    it 'should not invoke submit_application for invalid application' do
      invalid_app.submit!
    end

    it 'should record transition on a valid application submit' do
      expect(valid_app).to receive(:record_transition)
      valid_app.submit!
    end

    it 'should record transition on an invalid application submit' do
      expect(invalid_app).to receive(:record_transition)
      invalid_app.submit!
    end

    it 'should not create verification documents for schema invalid application' do
      invalid_app.update_attributes!(hbx_id: nil)
      expect(invalid_app).to receive(:report_invalid)
      invalid_app.submit!
      expect(invalid_app.aasm_state).to eq 'draft'
      expect(applicant_primary2.verification_types.count).to eq 0
    end
  end

  describe '.create_verification_documents' do

    it 'should create income and mec verification types' do
      application.send(:create_verification_documents)
      expect(applicant1.verification_types.count). to eq 2
      expect(applicant2.verification_types.count). to eq 2
    end

    it 'should have both income and mec in pending state' do
      application.active_applicants.each do |applicant|
        applicant.verification_types.each do |type|
          expect(type.validation_status). to eq('pending')
        end
      end
    end
  end

  describe '.delete_verification_documents' do

    before do
      application.send(:create_verification_documents)
    end

    it 'should delete income and mec verification types' do
      expect(applicant1.verification_types.count). to eq 2
      application.send(:delete_verification_documents)
      application.active_applicants.each do |applicant|
        expect(applicant.verification_types.count). to eq 0
      end
    end
  end

  context 'add_eligibility_determination' do
    let(:xml) { File.read(::FinancialAssistance::Engine.root.join('spec', 'test_data', 'haven_eligibility_response_payloads', 'verified_1_member_family.xml')) }
    let(:message) do
      {determination_http_status_code: 200, has_eligibility_response: true,
       haven_app_id: '1234', haven_ic_id: '124', eligibility_response_payload: xml}
    end
    let!(:person10) do
      FactoryBot.create(:person, :with_consumer_role, hbx_id: '20944967', last_name: 'Test', first_name: 'Domtest34', ssn: '243108282', dob: Date.new(1984, 3, 8))
    end

    let(:family10_id) { BSON::ObjectId.new }
    let(:family_member10_id) { BSON::ObjectId.new }
    let!(:application10) { FactoryBot.create(:financial_assistance_application, family_id: family10_id, hbx_id: '5979ec3cd7c2dc47ce000000', aasm_state: 'submitted') }
    let!(:ed) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application10, csr_percent_as_integer: nil, max_aptc: 0.0) }
    let!(:applicant10) do
      FactoryBot.create(:applicant, application: application10,
                                    family_member_id: family_member10_id,
                                    person_hbx_id: person10.hbx_id,
                                    ssn: '243108282',
                                    dob: Date.new(1984, 3, 8),
                                    first_name: 'Domtest34',
                                    last_name: 'Test',
                                    eligibility_determination_id: ed.id)
    end

    before do
      ed.update_attributes!(hbx_assigned_id: '205828')
      application10.add_eligibility_determination(message)
    end

    it 'should update eligibility_determination object' do
      expect(ed.max_aptc.to_f).to eq(47.78)
    end

    it 'should update applicant object' do
      expect(applicant10.is_ia_eligible).to be_truthy
    end
  end
end
