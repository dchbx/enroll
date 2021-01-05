require 'rails_helper'

describe FamilyMember, dbclean: :after_each do
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

describe FamilyMember, "given a person", dbclean: :after_each do
  let(:person) { Person.new }
  subject { FamilyMember.new(:person => person) }

  it "delegates #ivl_coverage_selected to person" do
    expect(person).to receive(:ivl_coverage_selected)
    subject.ivl_coverage_selected
  end
end


describe FamilyMember, "given a person", dbclean: :after_each do
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
    let(:broker_role)   {FactoryBot.create(:broker_role)}
    let(:broker_role2)  {FactoryBot.create(:broker_role)}

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

describe FamilyMember, "which is inactive", dbclean: :after_each do
  # TODO: Note 7/17/2019 this wasn't even a finished block, xit'd out
  xit "can be reactivated with a specified relationship" do

  end
end

describe FamilyMember, "given a relationship to update", dbclean: :after_each do
  let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
  let(:relationship) { "spouse" }
  let(:person) { FactoryBot.build(:person) }
  subject { FactoryBot.build(:family_member, person: person, family: family) }

  it "should do nothing if the relationship is the same" do
    subject.update_relationship(subject.primary_relationship)
  end

  it "should update the relationship if different" do
    expect(subject.primary_relationship).not_to eq relationship
    subject.update_relationship(relationship)
    expect(subject.primary_relationship).to eq relationship
  end
end

describe FamilyMember, "aptc_benchmark_amount", dbclean: :after_each do
  let(:person) { FactoryBot.create(:person, :with_consumer_role, dob: TimeKeeper.date_of_record - 46.years)}
  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person, e_case_id: "family_test#1000")}
  let(:enrollment) {FactoryBot.create(:hbx_enrollment, family: family, product: product, effective_on: TimeKeeper.date_of_record)}
  let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }
  let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
  before do
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(enrollment.effective_on)}.update_attributes!(slcsp_id: product.id)
  end

  it 'should return valid benchmark value' do
    family_member = FamilyMember.new(:person => person)
    expect(family_member.aptc_benchmark_amount(enrollment)).to eq 198.86
  end
end

describe FamilyMember, 'call back deactivate_tax_households on update', dbclean: :after_each do
  let!(:person) {FactoryBot.create(:person)}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:household) {FactoryBot.create(:household, family: family)}
  let!(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(2020, 1, 1), effective_ending_on: nil, is_eligibility_determined: true)}
  let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, csr_percent_as_integer: 10)}
  it 'should deactivate eligibility when member is updated' do
    family.active_household.tax_households << tax_household
    family.save!
    family.primary_applicant.update_attributes!(is_active: false)
    family.reload
    expect(family.active_household.tax_households.first.effective_ending_on).not_to eq nil
  end
end

# TODO: Renable the spec on the after hook is enabled on family_member model
# describe FamilyMember, 'call back deactivate_tax_households on create', dbclean: :after_each do
#   let!(:person) {FactoryBot.create(:person)}
#   let!(:spouse)  { FactoryBot.create(:person)}
#   let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
#   let!(:household) {FactoryBot.create(:household, family: family)}
#   let!(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(2020, 1, 1), effective_ending_on: nil, is_eligibility_determined: true)}
#   let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, csr_percent_as_integer: 10)}
#   it 'should deactivate eligibility when member is updated' do
#     family.active_household.tax_households << tax_household
#     family.save!
#     family.family_members.create(is_primary_applicant: false, person: spouse)
#     family.reload
#     expect(family.active_household.tax_households.first.effective_ending_on).not_to eq nil
#   end
# end
