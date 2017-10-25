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

  it "delegates #ivl_coverage_selected to person" do
    expect(person).to receive(:ivl_coverage_selected)
    subject.ivl_coverage_selected
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


describe "person attr & params" do
  include_examples "family_member examples"
  include_examples "phone numbers"
  include_examples "addresses attr examples"
  include_examples "person params examples"
  include_examples "email attr examples"

  let!(:family_member) {FactoryGirl.build(:family_member, family: family, person: person2)}
  let!(:dob) {"1972-04-04"}

  let!(:family_member_person_attributes) { person_params2.merge({"addresses" => array_address1})}

  let!(:primary_person_attributes){person_primary_params2.merge({"phones_attributes"=> array_phone1, "addresses_attributes" => array_address1, "emails_attributes" => array_email1})}

  it "should be true for family member when passed with same params" do
    allow(family_member).to receive(:relationship).and_return 'spouse'
    allow(family_member).to receive(:is_applying_coverage).and_return 'true'
    allow(family_member).to receive(:eligible_immigration_status).and_return 'false'
    allow(person2).to receive(:us_citizen).and_return 'true'
    allow(family_member).to receive(:naturalized_citizen).and_return 'true'
    allow(family_member).to receive(:indian_tribe_member).and_return 'true'
    expect(family_member.family_mem_attr_changed?(family_member_person_attributes)).to eq true
  end

  it "should be false for family member when passed with different params" do
    allow(family_member).to receive(:relationship).and_return 'spouse'
    allow(family_member).to receive(:is_applying_coverage).and_return 'false'
    allow(family_member).to receive(:eligible_immigration_status).and_return 'false'
    allow(person2).to receive(:us_citizen).and_return 'true'
    allow(family_member).to receive(:naturalized_citizen).and_return 'true'
    allow(family_member).to receive(:indian_tribe_member).and_return 'true'
    expect(family_member.family_mem_attr_changed?(family_member_person_attributes)).to eq false
  end

  it "should be false for primary member when passed with different params" do
    allow(family.primary_family_member).to receive(:is_applying_coverage).and_return 'false'
    allow(family.primary_family_member).to receive(:eligible_immigration_status).and_return 'false'
    allow(person).to receive(:us_citizen).and_return 'true'
    allow(family.primary_family_member).to receive(:naturalized_citizen).and_return 'true'
    allow(family.primary_family_member).to receive(:indian_tribe_member).and_return 'true'
    expect(family.primary_family_member. primary_mem_attr_changed?(primary_person_attributes)).to eq false
  end

  it "should be false for primary member when passed with different params" do
    allow(family.primary_family_member).to receive(:is_applying_coverage).and_return 'true'
    allow(family.primary_family_member).to receive(:eligible_immigration_status).and_return 'false'
    allow(person).to receive(:us_citizen).and_return 'true'
    allow(family.primary_family_member).to receive(:naturalized_citizen).and_return 'true'
    allow(family.primary_family_member).to receive(:indian_tribe_member).and_return 'true'
    expect(family.primary_family_member. primary_mem_attr_changed?(primary_person_attributes)).to eq true
  end

end
