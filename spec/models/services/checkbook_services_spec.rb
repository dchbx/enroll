require 'rails_helper'

class ApplicationHelperModStubber
  extend ApplicationHelper
end

describe Services::CheckbookServices::PlanComparision do

  let(:census_employee) { FactoryGirl.build(:census_employee, first_name: person.first_name, last_name: person.last_name, dob: person.dob, ssn: person.ssn, employee_role_id: employee_role.id)}
  let(:household) { FactoryGirl.create(:household, family: person.primary_family)}
  let(:employee_role) { FactoryGirl.create(:employee_role, person: person)}
  let(:person) { FactoryGirl.create(:person, :with_family)}
  let!(:consumer_person) { FactoryGirl.create(:person, :with_consumer_role) }
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: consumer_person) }
  let(:plan_year){ FactoryGirl.create(:next_month_plan_year, :with_benefit_group)}
  let(:benefit_group){ plan_year.benefit_groups.first }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: census_employee.employee_role.person.primary_family.households.first, employee_role_id: employee_role.id, benefit_group_id: benefit_group.id)}
  let!(:hbx_enrollment1) { FactoryGirl.create(:hbx_enrollment, kind: "individual", consumer_role_id: consumer_person.consumer_role.id, household: family.active_household)}

  describe "when employee is not congress" do
    subject { Services::CheckbookServices::PlanComparision.new(hbx_enrollment,false) }
    let(:checkbook_url) {"http://checkbook_url"}
    let(:result) {double("HttpResponse" ,:parsed_response =>{"URL" => "http://checkbook_url"})}

    before :each do
      allow(Rails).to receive_message_chain('env.test?').and_return(false)
    end

    it "should generate non-congressional link" do
      if ApplicationHelperModStubber.plan_match_dc
        allow(subject).to receive(:construct_body_shop).and_return({})
        allow(HTTParty).to receive(:post).and_return(result)
        # expect(subject.generate_url).to eq Rails.application.config.checkbook_services_congress_url+"#{hbx_enrollment.effective_on.year}/"
        expect(subject.generate_url).to eq checkbook_url
      end
    end
  end

  describe "when user is consumer" do
    subject { Services::CheckbookServices::PlanComparision.new(hbx_enrollment1,false) }
    let(:checkbook_url) {"http://checkbook_url"}
    let(:result) {double("HttpResponse" ,:parsed_response =>{"URL" => checkbook_url})}

    it "should generate consumer link" do
      if ApplicationHelperModStubber.plan_match_dc
        allow(subject).to receive(:construct_body_ivl).and_return({})
        allow(HTTParty).to receive(:post).with(Rails.application.config.checkbook_services_base_url,
          {:body=>"{}", :headers=>{"Content-Type"=>"application/json"}}).and_return(result)
        expect(subject.generate_url).to eq checkbook_url
      end
    end
  end

  describe "when checkbook response is irregular or an exception is raised" do
    subject { Services::CheckbookServices::PlanComparision.new(hbx_enrollment1,false) }
    let(:checkbook_url) {"http://checkbook_url"}
    let(:result) {double("HttpResponse" ,:parsed_response =>{"URL" => ""})}
    before { Rails.env.stub(:test? => false) }
    it "should generate consumer link" do
        if ApplicationHelperModStubber.plan_match_dc
          allow(subject).to receive(:construct_body_ivl).and_return({})
          allow(HTTParty).to receive(:post).with(Rails.application.config.checkbook_services_base_url,
            {:body=>"{}", :headers=>{"Content-Type"=>"application/json"}}).
            and_raise(Exception)
          expect(subject.generate_url).to eq false
        end
      end
  end
  
  describe "#build_congress_employee_age" do 
    subject { Services::CheckbookServices::PlanComparision.new(hbx_enrollment,true) }
    context "when active household is present" do 
      let(:person_congress) { FactoryGirl.create(:person, :with_active_consumer_role, :with_consumer_role , dob: "1980-01-01") }
      let(:person_congress_spouse) { FactoryGirl.create(:person, dob: "1984-01-01" ) }
      let(:enrollment_memeber_congress){ double }
      let(:enrollment_memeber_spouse){ double }
      it "should return correct age" do
        allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([enrollment_memeber_congress,enrollment_memeber_spouse])
        allow(enrollment_memeber_congress).to receive_message_chain(:family_member,:person).and_return(person_congress)
        allow(enrollment_memeber_spouse).to receive_message_chain(:family_member,:person).and_return(person_congress_spouse)
        expect(subject.build_congress_employee_age).to include({:dob => "1984-01-01"})
        expect(subject.build_congress_employee_age).to include({:dob => "1980-01-01"})
      end
    end
  end


  describe "#csr_value" do
    let!(:ivl_person)       { FactoryGirl.create(:person, :with_consumer_role) }
    let!(:ivl_family)       { FactoryGirl.create(:family, :with_primary_family_member_and_dependent, person: ivl_person) }
    let!(:ivl_household)    { ivl_family.active_household }
    let!(:primary_fm_id)    { ivl_family.primary_applicant.id.to_s }
    let!(:dependent_fm_id)  { ivl_family.family_members[1].id.to_s }
    let!(:ivl_tax_household){ FactoryGirl.create(:tax_household, household: ivl_household, effective_ending_on: nil) }
    let!(:ivl_ed)           { FactoryGirl.create(:eligibility_determination, tax_household: ivl_tax_household) }
    let!(:thh_start_on)     { ivl_tax_household.effective_starting_on }
    let!(:ivl_enrollment)   { FactoryGirl.create(:hbx_enrollment, effective_on: thh_start_on, kind: 'individual', household: ivl_household, consumer_role_id: ivl_person.consumer_role.id.to_s) }
    let!(:ivl_enr_member)   { FactoryGirl.create(:hbx_enrollment_member, applicant_id: primary_fm_id, hbx_enrollment: ivl_enrollment) }
    let!(:ivl_thhm)         { ivl_tax_household.tax_household_members << TaxHouseholdMember.new(applicant_id: primary_fm_id, is_ia_eligible: true) }

    subject { ::Services::CheckbookServices::PlanComparision.new(ivl_enrollment,false) }

    context 'when all members are aptc eligible' do
      ::EligibilityDetermination::CSR_KINDS.each do |csr_kind|
        it "should return a value mapped to #{csr_kind} as all members are aptc eligible" do
          ivl_ed.update_attributes!(csr_eligibility_kind: csr_kind)
          csr = ::EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]
          expect(subject.csr_value).to eq csr.prepend('-')
        end
      end
    end

    context 'when at least one of the members are aptc ineligible' do
      let!(:ivl_thhm1)          { ivl_tax_household.tax_household_members << TaxHouseholdMember.new(applicant_id: dependent_fm_id, is_medicaid_chip_eligible: true) }
      let!(:ivl_enr_member1)    { FactoryGirl.create(:hbx_enrollment_member, applicant_id: dependent_fm_id, hbx_enrollment: ivl_enrollment, is_subscriber: false) }

      it 'should return -01' do
        expect(subject.csr_value).to eq '-01'
      end
    end

    context 'when there is no active tax household' do
      it 'should return -01' do
        ivl_tax_household.update_attributes!(effective_ending_on: TimeKeeper.date_of_record.end_of_year)
        expect(subject.csr_value).to eq '-01'
      end
    end
  end

  describe "#aptc_value  " do
    subject { Services::CheckbookServices::PlanComparision.new(hbx_enrollment,true) }
    context "when active household is present" do
      let(:tax_household) {FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year,1,1), effective_ending_on: nil)}
      let(:sample_max_aptc_1) {511.78}
      let(:sample_csr_percent_1) {87}
      let(:eligibility_determination_1) {EligibilityDetermination.new(determined_at: TimeKeeper.date_of_record.beginning_of_year, max_aptc: sample_max_aptc_1, csr_percent_as_integer: sample_csr_percent_1 )}

      it "should return max aptc" do
        allow(tax_household).to receive(:eligibility_determinations).and_return [eligibility_determination_1]
        allow(hbx_enrollment).to receive_message_chain(:household,:latest_active_tax_households_with_year).and_return(tax_household)
        expect(subject.aptc_value).to eq tax_household.latest_eligibility_determination.max_aptc.to_i
      end
    end
     context "when active household  not present" do
      it "should return max NULL" do
        allow(hbx_enrollment).to receive_message_chain(:household,:latest_active_tax_households_with_year).and_return(nil)
        expect(subject.aptc_value).to eq "NULL"
      end
    end
  end

  describe "when employee is congress member" do
    subject { Services::CheckbookServices::PlanComparision.new(hbx_enrollment,true) }
    let(:checkbook_url) {"http://checkbook_url"}

    it "should generate congressional url" do
     if ApplicationHelperModStubber.plan_match_dc
       allow(subject).to receive(:construct_body_shop).and_return({})
       expect(subject.generate_url).to eq checkbook_url
      end
    end
  end
end
