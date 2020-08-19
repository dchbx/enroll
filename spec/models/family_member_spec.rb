require 'rails_helper'

describe FamilyMember do
  subject { FamilyMember.new(:is_primary_applicant => nil, :is_coverage_applicant => nil) }

  before(:each) do
    subject.valid?
  end

  it "should validate the presence of a person" do
    expect(subject).to have_errors_on(:person_id)
  end
  it "should validate the presence of is_primary_applicant" do
    expect(subject).to have_errors_on(:is_primary_applicant)
  end
  it "should validate the presence of is_coverage_applicant" do
    expect(subject).to have_errors_on(:is_coverage_applicant)
  end

end

describe FamilyMember, "given a person" do
  let(:person) { Person.new }
  subject { FamilyMember.new(:person => person) }

  it "delegates #trigger_hub_call to person" do
    expect(person).to receive(:trigger_hub_call)
    subject.trigger_hub_call
  end
end

describe "application_for_verifications" do
  include_examples 'draft application with 2 applicants'

  before do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:is_application_valid?).and_return(true)
    allow(family).to receive(:application_applicable_year).and_return application.assistance_year
    application.submit!
  end

  it 'should return application if family member is present' do
    expect(second_family_member.application_for_verifications).to eq application
  end

  it 'should not return application if family member is not present' do
    expect(family_member_not_on_application.application_for_verifications).to eq nil
  end
end


describe FamilyMember, "given a person" do
  let(:person) { create :person ,:with_family }

  it "should error when trying to save duplicate family member" do
    family_member = FamilyMember.new(:person => person) 
    person.families.first.family_members << family_member
    person.families.first.family_members << family_member
    expect(family_member.errors.full_messages.join(",")).to match(/Family members Duplicate family_members for person/)
  end
end

describe FamilyMember, dbclean: :after_each do
  context "a family with members exists" do
    include_context "BradyBunchAfterAll"

    before :each do
      create_brady_families
    end

    let(:family_member_id) {mikes_family.primary_applicant.id}

    it "FamilyMember.find(id) should work" do
      expect(FamilyMember.find(family_member_id).id.to_s).to eq family_member_id.to_s
    end

    it "should be possible to find the primary_relationship" do
      mikes_family.dependents.each do |dependent|
        if brady_children.include?(dependent.person)
          expect(dependent.primary_relationship).to eq "child"
        else
          expect(dependent.primary_relationship).to eq "spouse"
        end
      end
    end
  end

  let(:p0) {Person.create!(first_name: "Dan", last_name: "Aurbach")}
  let(:p1) {Person.create!(first_name: "Patrick", last_name: "Carney")}
  let(:ag) { 
    fam = Family.new
    fam.family_members.build(
      :person => p0,
      :is_primary_applicant => true
    )
    fam.save!
    fam
  }
  let(:family_member_params) {
    { person: p1,
      is_primary_applicant: true,
      is_coverage_applicant: true,
      is_consent_applicant: true,
      is_active: true}
  }

  context "parent" do
    it "should equal to family" do
      family_member = ag.family_members.create(**family_member_params)
      expect(family_member.parent).to eq ag
    end

    it "should raise error with nil family" do
      family_member = FamilyMember.new(**family_member_params)
      expect{family_member.parent}.to raise_error(RuntimeError, "undefined parent family")
    end
  end

  context "person" do
    it "with person" do
      family_member = FamilyMember.new(**family_member_params)
      family_member.person= p1
      expect(family_member.person).to eq p1
    end

    it "without person" do
      expect(FamilyMember.new(**family_member_params.except(:person)).valid?).to be_falsey
    end
  end

  context "broker" do
    let(:broker_role)   {FactoryGirl.create(:broker_role)}
    let(:broker_role2)  {FactoryGirl.create(:broker_role)}

    it "with broker_role" do
      family_member = ag.family_members.create(**family_member_params)
      family_member.broker= broker_role
      expect(family_member.broker).to eq broker_role
    end

    it "without broker_role" do
      family_member = ag.family_members.create(**family_member_params)
      family_member.broker = broker_role
      expect(family_member.broker).to eq broker_role

      family_member.broker = broker_role2
      expect(family_member.broker).to eq broker_role2
    end
  end

  context "comments" do
    it "with blank" do
      family_member = ag.family_members.create({
        person: p0,
        is_primary_applicant: true,
        is_coverage_applicant: true,
        is_consent_applicant: true,
        is_active: true,
        comments: [{priority: 'normal', content: ""}]
      })

      expect(family_member.errors[:comments].any?).to eq true
    end

    it "without blank" do
      family_member = ag.family_members.create({
        person: p0,
        is_primary_applicant: true,
        is_coverage_applicant: true,
        is_consent_applicant: true,
        is_active: true,
        comments: [{priority: 'normal', content: "aaas"}]
      })

      expect(family_member.errors[:comments].any?).to eq false
      expect(family_member.comments.size).to eq 1
    end
  end

  describe "instantiates object." do
    it "sets and gets all basic model fields and embeds in parent class" do
      a = FamilyMember.new(
        person: p0,
        is_primary_applicant: true,
        is_coverage_applicant: true,
        is_consent_applicant: true,
        is_active: true
        )

      a.family = ag

      expect(a.person.last_name).to eql(p0.last_name)
      expect(a.person_id).to eql(p0._id)

      expect(a.is_primary_applicant?).to eql(true)
      expect(a.is_coverage_applicant?).to eql(true)
      expect(a.is_consent_applicant?).to eql(true)
    end
  end
end

# describe FamilyMember, "which is inactive" do
#   it "can be reactivated with a specified relationship"
# end

describe "for families with financial assistance application" do
  let(:person) { FactoryGirl.create(:person)}
  let(:person1) { FactoryGirl.create(:person)}
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }

  before(:each) do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
  end

  context "family_member added when application is in progress" do
    it "should create an applicant with the family_member_id of the added member" do
      family.applications.create!
      expect(family.application_in_progress.active_applicants.count).to eq 0
      fm = family.family_members.create!({person_id: person1.id, is_primary_applicant: false, is_coverage_applicant: true})
      expect(family.application_in_progress.active_applicants.count).to eq 1
      expect(family.application_in_progress.active_applicants.first.family_member_id).to eq fm.id
    end
  end
end

describe FamilyMember, "aptc_benchmark_amount" do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role, dob: TimeKeeper.date_of_record - 46.years)}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person, e_case_id: "family_test#1000")}
  let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', csr_variant_id: '01', active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122302-01") }

  before do
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}.update_attributes!(slcsp_id: plan.id)
  end
  
  it "should return valid benchmark value" do
    family_member = FamilyMember.new(:person => person) 
    expect(family_member.aptc_benchmark_amount.round(2)).to eq 508.70
  end
end
