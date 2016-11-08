require 'rails_helper'

describe Family, "given a primary applicant and a dependent" do
  let(:person) { Person.new }
  let(:dependent) { Person.new }
  let(:household) { Household.new(:is_active => true) }

  let(:family_member_person) { FamilyMember.new(is_primary_applicant: true, is_consent_applicant: true, person: person) }
  let(:family_member_dependent) { FamilyMember.new(person: dependent) }

  subject { Family.new(:households => [household], :family_members => [family_member_person, family_member_dependent]) }

  it "should remove the household member when it removes the dependent" do
    expect(household).to receive(:remove_family_member).with(family_member_dependent)
    subject.remove_family_member(dependent)
  end

  context "with enrolled hbx enrollments" do
    let(:mock_hbx_enrollment) { instance_double(HbxEnrollment) }
    before do
      allow(household).to receive(:enrolled_hbx_enrollments).and_return([mock_hbx_enrollment])
    end

    it "enrolled hbx enrollments should come from latest household" do
      expect(subject.enrolled_hbx_enrollments).to eq subject.latest_household.enrolled_hbx_enrollments
    end
  end

end

describe Family, type: :model, dbclean: :after_each do

  let(:spouse)  { FactoryGirl.create(:person)}
  let(:person) do
    p = FactoryGirl.build(:person)
    p.person_relationships.build(relative: spouse, kind: "spouse")
    p.save
    p
  end

  let(:family_member_person) { FamilyMember.new(is_primary_applicant: true, is_consent_applicant: true, person: person) }
  let(:family_member_spouse) { FamilyMember.new(person: spouse) }

  context "when built" do
    context "with valid parameters" do
      let(:now) { DateTime.current }
      let(:user)  { "rspec@dchealthlink.com" }
      let(:curam_id) { "6754632abc" }
      let(:e_case_id) { curam_id }
      let(:renewal_consent_through_year) { 2017 }
      let(:submitted_at) { now }
      let(:updated_by) { user }

      let(:valid_params) do
        {
          e_case_id: e_case_id,
          renewal_consent_through_year: renewal_consent_through_year,
          submitted_at: submitted_at,
          updated_by: updated_by
        }
      end

      let(:params)  { valid_params }
      let(:family)  { Family.new(**params) }

      context "and the primary applicant is missing" do
        before do
          family.family_members = [family_member_spouse]
          family.valid?
        end

        it "should not be valid" do
          expect(family.errors[:family_members].any?).to be_truthy
        end

        it "should have no enrolled hbx enrollments" do
          expect(family.enrolled_hbx_enrollments).to eq []
        end
      end

      context "and primary applicant and family members are added" do
        before do
          family.family_members = [family_member_person, family_member_spouse]
          family.save
        end

        it "all the added people are represented as family members" do
          expect(family.family_members.size).to eq 2
        end

        it "the correct person is primary applicant" do
          expect(family.primary_applicant.person).to eq person
        end

        it "the correct person is consent applicant" do
          expect(family.consent_applicant.person).to eq person
        end

        it "has an irs group" do
          expect(family.irs_groups.size).to eq 1
        end

        it "has a household that is associated with irs group" do
          expect(family.households.size).to eq 1
          expect(family.households.first.irs_group).to eq family.irs_groups.first
        end

        it "is persistable" do
          expect(family.valid?).to be_truthy
        end

        context "and it is persisted" do
          let!(:saved_family) do
            f = family
            f.save
            f
          end

          it "should be findable" do
            expect(Family.find(saved_family.id).id.to_s).to eq saved_family.id.to_s
          end

          context "and one of the family members is not related to the primary applicant" do
            let(:alice) { FactoryGirl.create(:person, first_name: "alice") }
            let(:non_family_member) { FamilyMember.new(person: alice) }

            before do
              family.family_members << non_family_member
              family.valid?
            end

            it "should not be valid" do
              expect(family.errors[:family_members].any?).to be_truthy
            end

            context "and the non-related person is a responsible party" do
              it "to be added for IVL market"
            end
          end

          context "and one of the same family members is added again" do
            before do
              family.family_members << family_member_spouse.dup
              family.valid?
            end

            it "should not be valid" do
              expect(family.errors[:family_members].any?).to be_truthy
            end
          end

          context "and a second primary applicant is added" do
            let(:bob) do
              p = FactoryGirl.create(:person, first_name: "Bob")
              person.person_relationships << PersonRelationship.new(relative: p, kind: "child")
              p
            end

            let(:family_member_child) { FamilyMember.new(is_primary_applicant: true, is_consent_applicant: true, person: bob) }

            before do
              family.family_members << family_member_child
              family.valid?
            end

            it "should not be valid" do
              expect(family.errors[:family_members].any?).to be_truthy
            end
          end

          context "and another family is created with same members" do

            context "and the primary applicant is the same person" do
              let(:second_family) { Family.new }
              before do
                second_family.family_members = [family_member_person.dup, family_member_spouse.dup]
              end

              it "should not be valid" do
                expect(second_family.valid?).to be_falsey
              end
            end

            context "and the primary applicant is not the same person" do
              let(:second_family) { Family.new }
              let(:second_family_member_spouse) { FamilyMember.new(is_primary_applicant: true, is_consent_applicant: true, person: spouse) }
              let(:second_family_member_person) { FamilyMember.new(person: person) }

              before do
                spouse.person_relationships.build(:relative_id => person.id, :kind => "spouse")
                second_family.family_members = [second_family_member_person, second_family_member_spouse]
              end

              it "should be valid" do
                expect(second_family.valid?).to be_truthy
              end
            end
          end
        end
      end
    end
  end

  context "after it's persisted" do
    include_context "BradyBunchAfterAll"

    before(:each) do
      create_brady_families
    end

    context "when you add a family member" do
      it "there is a corresponding coverage household member" do
        covered_bradys = carols_family.households.first.immediate_family_coverage_household.coverage_household_members.collect(){|m| m.family_member.person.full_name}
        expect(covered_bradys).to contain_exactly(*bradys.collect(&:full_name))
      end
    end

    context "when a broker account is created for the Family" do
      let(:broker_agency_profile) { FactoryGirl.build(:broker_agency_profile) }
      let(:writing_agent)         { FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile.id) }
      let(:broker_agency_profile2) { FactoryGirl.build(:broker_agency_profile) }
      let(:writing_agent2)         { FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile2.id) }
      it "adds a broker agency account" do
        carols_family.hire_broker_agency(writing_agent.id)
        expect(carols_family.broker_agency_accounts.length).to eq(1)
      end
      it "adding twice only gives two broker agency accounts" do
        carols_family.hire_broker_agency(writing_agent.id)
        carols_family.hire_broker_agency(writing_agent.id)
        expect(carols_family.broker_agency_accounts.unscoped.length).to eq(2)
        expect(Family.by_writing_agent_id(writing_agent.id).count).to eq(1)
      end
      it "new broker adds a broker_agency_account" do
        carols_family.hire_broker_agency(writing_agent.id)
        carols_family.hire_broker_agency(writing_agent2.id)
        expect(carols_family.broker_agency_accounts.unscoped.length).to eq(2)
        expect(carols_family.broker_agency_accounts[0].is_active).to be_falsey
        expect(carols_family.broker_agency_accounts[1].is_active).to be_truthy
        expect(carols_family.broker_agency_accounts[1].writing_agent_id).to eq(writing_agent2.id)
      end
      it "carol changes brokers" do
        carols_family.hire_broker_agency(writing_agent.id)
        carols_family.hire_broker_agency(writing_agent2.id)
        expect(Family.by_writing_agent_id(writing_agent.id).count).to eq(0)
        expect(Family.by_writing_agent_id(writing_agent2.id).count).to eq(1)
      end
      it "writing_agent is popular" do
        carols_family.hire_broker_agency(writing_agent.id)
        carols_family.hire_broker_agency(writing_agent2.id)
        carols_family.hire_broker_agency(writing_agent.id)
        mikes_family.hire_broker_agency(writing_agent.id)
        expect(Family.by_writing_agent_id(writing_agent.id).count).to eq(2)
        expect(Family.by_writing_agent_id(writing_agent2.id).count).to eq(0)
      end
      it "broker agency profile is popular" do
        carols_family.hire_broker_agency(writing_agent.id)
        carols_family.hire_broker_agency(writing_agent2.id)
        carols_family.hire_broker_agency(writing_agent.id)
        mikes_family.hire_broker_agency(writing_agent.id)
        expect(Family.by_broker_agency_profile_id(broker_agency_profile.id).count).to eq(2)
        expect(Family.by_broker_agency_profile_id(broker_agency_profile2.id).count).to eq(0)
      end

    end

  end

  ## TODO: Add method
  # describe HbxEnrollment, "#is_eligible_to_enroll?", type: :model do
  #   context "family is under open enrollment period" do
  #     it "should return true" do
  #     end
  #
  #     context "and employee_role is under Special Enrollment Period" do
  #       it "should return true" do
  #       end
  #     end
  #   end
  #
  #   context "employee_role is under Special Enrollment Period" do
  #     it "should return true" do
  #     end
  #   end
  #
  #   context "outside family open enrollment" do
  #     it "should return false" do
  #     end
  #   end
  #
  #   context "employee_role is not under SEP" do
  #     it "should return false" do
  #     end
  #   end
  # end

end

describe Family do
  let(:family) { Family.new }

  describe "with no special enrollment periods" do
    context "family has never had a special enrollment period" do

      it "should indicate no active SEPs" do
        expect(family.is_under_special_enrollment_period?).to be_falsey
      end

      it "current_special_enrollment_periods should return []" do
        expect(family.current_special_enrollment_periods).to eq []
      end
    end
  end

  describe "family has a past QLE, but Special Enrollment Period has expired" do
    before :each do
      expired_sep = FactoryGirl.build(:special_enrollment_period, :expired)
      family.special_enrollment_periods << expired_sep
    end

    it "should have the SEP instance" do
      expect(family.special_enrollment_periods.size).to eq 1
    end

    it "should return a SEP class" do
      expect(family.special_enrollment_periods.first).to be_a SpecialEnrollmentPeriod
    end

    it "should indicate no active SEPs" do
      expect(family.is_under_special_enrollment_period?).to be_falsey
    end

    it "current_special_enrollment_periods should return []" do
      expect(family.current_special_enrollment_periods).to eq []
    end
  end

  context "family has a QLE and is under a SEP" do
    before do
      @current_sep = FactoryGirl.build(:special_enrollment_period)
      family.special_enrollment_periods << @current_sep
    end

    it "should indicate SEP is active" do
      expect(family.is_under_special_enrollment_period?).to be_truthy
    end

    it "should return one current_special_enrollment" do
      expect(family.current_special_enrollment_periods.size).to eq 1
      expect(family.current_special_enrollment_periods.first).to eq @current_sep
    end
   end

  context "and the family is under more than one SEP" do
    before do
      current_sep = FactoryGirl.build(:special_enrollment_period)
      family.special_enrollment_periods << current_sep
      another_current_sep = FactoryGirl.build(:special_enrollment_period, qle_on: 4.days.ago.to_date)
      family.special_enrollment_periods << another_current_sep
    end
    it "should return multiple current_special_enrollment" do
      expect(family.current_special_enrollment_periods.size).to eq 2
    end
  end

  context "earliest_effective_sep" do
    before do
      date1 = TimeKeeper.date_of_record - 20.days
      @current_sep = FactoryGirl.build(:special_enrollment_period, qle_on: date1, effective_on: date1)
      family.special_enrollment_periods << @current_sep
      date2 = TimeKeeper.date_of_record - 10.days
      @another_current_sep = FactoryGirl.build(:special_enrollment_period, qle_on: date2, effective_on: date2)
      family.special_enrollment_periods << @another_current_sep
    end

    it "should return earliest sep when all active" do
      expect(@current_sep.is_active?).to eq true
      expect(@another_current_sep.is_active?).to eq true
      expect(family.earliest_effective_sep).to eq @current_sep
    end

    it "should return earliest active sep" do
      date3 = TimeKeeper.date_of_record - 200.days
      sep = FactoryGirl.build(:special_enrollment_period, qle_on: date3, effective_on: date3)
      family.special_enrollment_periods << sep
      expect(@current_sep.is_active?).to eq true
      expect(@another_current_sep.is_active?).to eq true
      expect(sep.is_active?).to eq false
      expect(family.earliest_effective_sep).to eq @current_sep
    end
  end

  context "latest_shop_sep" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    before do
      @qlek = FactoryGirl.create(:qualifying_life_event_kind, market_kind: 'shop', is_active: true)
      date1 = TimeKeeper.date_of_record - 20.days
      @current_sep = FactoryGirl.build(:special_enrollment_period, qle_on: date1, effective_on: date1, qualifying_life_event_kind: @qlek, effective_on_kind: 'first_of_month')
      family.special_enrollment_periods << @current_sep
      date2 = TimeKeeper.date_of_record - 10.days
      @another_current_sep = FactoryGirl.build(:special_enrollment_period, qle_on: date2, effective_on: date2, qualifying_life_event_kind: @qlek, effective_on_kind: 'first_of_month')
      family.special_enrollment_periods << @another_current_sep
    end

    it "should return latest active sep" do
      date3 = TimeKeeper.date_of_record - 200.days
      sep = FactoryGirl.build(:special_enrollment_period, qle_on: date3, effective_on: date3, qualifying_life_event_kind: @qlek, effective_on_kind: 'first_of_month')
      family.special_enrollment_periods << sep
      family.save
      expect(@current_sep.is_active?).to eq true
      expect(@another_current_sep.is_active?).to eq true
      expect(sep.is_active?).to eq false
      expect(family.latest_shop_sep).to eq @another_current_sep
    end
  end

  context "terminate_date_for_shop_by_enrollment" do
    it "without latest_shop_sep" do
      expect(family.terminate_date_for_shop_by_enrollment).to eq TimeKeeper.date_of_record.end_of_month
    end

    context "with latest_shop_sep" do
      let(:qlek) { FactoryGirl.build(:qualifying_life_event_kind, reason: 'death') }
      let(:date) { TimeKeeper.date_of_record - 10.days }
      let(:normal_sep) { FactoryGirl.build(:special_enrollment_period, qle_on: date) }
      let(:death_sep) { FactoryGirl.build(:special_enrollment_period, qle_on: date, qualifying_life_event_kind: qlek) }
      let(:hbx) { HbxEnrollment.new }

      it "normal sep" do
        allow(family).to receive(:latest_shop_sep).and_return normal_sep
        expect(family.terminate_date_for_shop_by_enrollment).to eq date.end_of_month
      end

      it "death sep" do
        allow(family).to receive(:latest_shop_sep).and_return death_sep
        expect(family.terminate_date_for_shop_by_enrollment).to eq date
      end

      it "when original terminate date before hbx effective_on" do
        allow(family).to receive(:latest_shop_sep).and_return normal_sep
        allow(normal_sep).to receive(:qle_on).and_return date.end_of_month
        allow(hbx).to receive(:effective_on).and_return (date.end_of_month)
        expect(family.terminate_date_for_shop_by_enrollment(hbx)).to eq (TimeKeeper.date_of_record.end_of_month)
      end

      it "when qle_on is less than hbx effective_on" do
        effective_on = date + 10.days
        allow(family).to receive(:latest_shop_sep).and_return normal_sep
        allow(hbx).to receive(:effective_on).and_return effective_on
        expect(family.terminate_date_for_shop_by_enrollment(hbx)).to eq effective_on
      end
    end
  end
end

describe "special enrollment periods" do
=begin
  include_context "BradyBunchAfterAll"

  before :each do
    create_brady_families
  end

  let(:family) { mikes_family }
  let(:current_sep) { FactoryGirl.build(:special_enrollment_period) }
  let(:another_current_sep) { FactoryGirl.build(:special_enrollment_period, qle_on: 4.days.ago.to_date) }
  let(:expired_sep) { FactoryGirl.build(:special_enrollment_period, :expired) }
=end
  context "attempt to add new SEP with same QLE and date as existing SEP" do
    before do
    end

    it "should not save as a duplicate"
  end
end


describe Family, ".find_or_build_from_employee_role:", type: :model, dbclean: :after_each do

  let(:submitted_at)  { DateTime.current}
  let(:spouse)        { FactoryGirl.create(:person, last_name: "richards", first_name: "denise") }
  let(:child)         { FactoryGirl.create(:person, last_name: "sheen", first_name: "sam") }
  let(:grandpa)       { FactoryGirl.create(:person, last_name: "sheen", first_name: "martin") }

  let(:married_relationships) { [PersonRelationship.new(relative: spouse, kind: "spouse"),
                                 PersonRelationship.new(relative: child, kind: "child")] }
  let(:family_relationships)  {  married_relationships <<
                                 PersonRelationship.new(relative: grandpa, kind: "grandparent") }

  let(:single_dude)   { FactoryGirl.create(:person, last_name: "sheen", first_name: "tigerblood") }
  let(:married_dude)  { FactoryGirl.create(:person, last_name: "sheen", first_name: "chuck",
                                           person_relationships: married_relationships ) }
  let(:family_dude)   { FactoryGirl.create(:person, last_name: "sheen", first_name: "charles",
                                           person_relationships: family_relationships ) }

  let(:single_employee_role)    { FactoryGirl.create(:employee_role, person: single_dude) }
  let(:married_employee_role)   { FactoryGirl.create(:employee_role, person: married_dude) }
  let(:family_employee_role)    { FactoryGirl.create(:employee_role, person: family_dude) }

  let(:single_family)          { Family.find_or_build_from_employee_role(single_employee_role) }
  let(:married_family)         { Family.find_or_build_from_employee_role(married_employee_role) }
  let(:large_family)           { Family.find_or_build_from_employee_role(family_employee_role) }


  context "when no families exist" do
    context "and employee is single" do

      it "should create one family_member with set attributes" do
        expect(single_family.family_members.size).to eq 1
        expect(single_family.family_members.first.is_primary_applicant).to eq true
        expect(single_family.family_members.first.is_coverage_applicant).to eq true
        expect(single_family.family_members.first.person).to eq single_employee_role.person
      end

      it "and create a household and associated IRS group" do
        expect(single_family.irs_groups.size).to eq 1
        expect(single_family.households.size).to eq 1
        expect(single_family.households.first.irs_group).to eq single_family.irs_groups.first
      end

      it "and create a coverage_household with one family_member" do
        expect(single_family.households.first.coverage_households.size).to eq 2
        expect(single_family.households.first.coverage_households.first.coverage_household_members.first.family_member).to eq single_family.family_members.first
      end
    end

    context "and employee has spouse and child" do

      it "creates two coverage_households and one will have all family members" do
        expect(married_family.households.first.coverage_households.size).to eq 2
      end

      it "and all family_members are members of this coverage_household" do
        expect(married_family.family_members.size).to eq 3
        expect(married_family.households.first.coverage_households.first.coverage_household_members.size).to eq 3

        expect(married_family.households.first.coverage_households.first.coverage_household_members.where(family_member_id: married_family.family_members[0]._id)).not_to be_nil
        expect(married_family.households.first.coverage_households.first.coverage_household_members.where(family_member_id: married_family.family_members[1]._id)).not_to be_nil
        expect(married_family.households.first.coverage_households.first.coverage_household_members.where(family_member_id: married_family.family_members[2]._id)).not_to be_nil
      end
    end

    context "and family includes extended family relationships" do

      it "creates two coverage households" do
        expect(large_family.households.first.coverage_households.size).to eq 2
      end

      it "and immediate family is in one coverage household" do
        immediate_family_coverage_household = large_family.households.first.coverage_households.where(:is_immediate_family => true).first
        expect(immediate_family_coverage_household.coverage_household_members.size).to eq 3
      end

      it "and extended family is in a second coverage household" do
        extended_family_coverage_household =  large_family.households.first.coverage_households.where(:is_immediate_family => false).first
        expect(extended_family_coverage_household.coverage_household_members.size).to eq 1
        # expect(extended_family_coverage_household.coverage_household_members.first.).to eq 1
      end

    end
  end

  context "family already exists with employee_role as primary_family_member" do
    let(:existing_primary_member) {existing}
    let(:existing_family) { FactoryGirl.create(:family)}

    it "should return the family for this employee_role"
  end

end

describe Family, "given an inactive member" do
  let(:ssn) { double }
  let(:dependent) {
    double(:id => "123456", :ssn => ssn, :last_name => last_name, :first_name => first_name, :dob => dob)
  }
  let(:last_name) { "A LAST NAME" }
  let(:first_name) { "A FIRST NAME" }
  let(:dob) { Date.new(2012,3,15) }
  let(:criteria) { double(:ssn => ssn) }
  let(:inactive_family_member) { FamilyMember.new(:is_active => false, :person => dependent) }

  subject { Family.new(family_members: [inactive_family_member]) }

  describe "given search which matches by ssn" do
    let(:criteria) { double(:ssn => ssn) }

    it "should find the member" do
      expect(subject.find_matching_inactive_member(criteria)).to eq inactive_family_member
    end
  end

  describe "given search which matches by first, last, and dob" do
    let(:criteria) { double(:ssn => nil, :first_name => first_name, :last_name => last_name, :dob => dob) }
    it "should find the member" do
      expect(subject.find_matching_inactive_member(criteria)).to eq inactive_family_member
    end
  end

  describe "given search criteria for that member which does not match" do
    let(:criteria) { double(:ssn => "123456789") }

    it "should not find the member" do
      expect(subject.find_matching_inactive_member(criteria)).to eq nil
    end
  end
end

describe Family, "with a primary applicant" do
  describe "given a new person and relationship to make to the primary applicant" do
    let(:primary_person_id) { double }
    let(:primary_applicant) { instance_double(Person, :person_relationships => [], :id => primary_person_id) }
    let(:relationship) { double }
    let(:employee_role) { double(:person => primary_applicant) }
    let(:dependent_id) { double }
    let(:dependent) { double(:id => dependent_id) }

    subject {
      fam = Family.new
      fam.build_from_employee_role(employee_role)
      fam
    }

    before(:each) do
      allow(primary_applicant).to receive(:ensure_relationship_with).with(dependent, "spouse")
      allow(primary_applicant).to receive(:find_relationship_with).with(dependent).and_return(nil)
    end

    it "should relate the person and create the family member" do
      # subject.relate_new_member(dependent, "spouse")
    end
  end
end

describe Family, "large family with multiple employees - The Brady Bunch", :dbclean => :after_all do
  include_context "BradyBunchAfterAll"

  before :all do
    create_brady_families
  end

  let(:family_member_id) {mikes_family.primary_applicant.id}

  it "should be possible to find the family_member from a family_member_id" do
    expect(Family.find_family_member(family_member_id).id.to_s).to eq family_member_id.to_s
  end

  context "Family.find_by_primary_applicant" do
    context "on Mike" do
      let(:find) {Family.find_by_primary_applicant(mike)}
      it "should find Mike's family" do
        expect(find.id.to_s).to eq mikes_family.id.to_s
      end
    end

    context "on Carol" do
      let(:find) {Family.find_by_primary_applicant(carol)}
      it "should find Carol's family" do
        expect(find.id.to_s).to eq carols_family.id.to_s
      end
    end
  end

  context "Family.find_by_person" do
    context "on Mike" do
      let(:find) {Family.find_all_by_person(mike).collect(&:id)}
      it "should find two families" do
        expect(find.count).to be 2
      end
      it "should find Mike's family" do
        expect(find).to include mikes_family.id
      end
      it "should find Carol's family" do
        expect(find).to include carols_family.id
      end
    end

    context "on Carol" do
      let(:find) {Family.find_all_by_person(carol).collect(&:id)}
      it "should find two families" do
        expect(find.count).to be 2
      end
      it "should find Mike's family" do
        expect(find).to include mikes_family.id
      end
      it "should find Carol's family" do
        expect(find).to include carols_family.id
      end
    end

    context "on Greg" do
      let(:find) {Family.find_all_by_person(greg).collect(&:id)}
      it "should find two families" do
        expect(find.count).to be 2
      end
      it "should find Mike's family" do
        expect(find).to include mikes_family.id
      end
      it "should find Carol's family" do
        expect(find).to include carols_family.id
      end
    end
  end
end

describe Family, "enrollment periods", :model, dbclean: :around_each do
  let(:person) { FactoryGirl.create(:person) }
  let(:family) { FactoryGirl.build(:family) }
  let!(:family_member) do
    fm = FactoryGirl.build(:family_member, person: person, family: family, is_primary_applicant: true, is_consent_applicant: true)
    family.family_members = [fm]
    fm
  end

  before do
    family.save
  end

  context "no open enrollment periods" do
    it "should not be in open enrollment" do
      expect(family.is_under_open_enrollment?).to be_falsey
    end

    it "should have no current eligible open enrollments" do
      expect(family.current_eligible_open_enrollments).to eq []
    end

    it "should not be in shop open enrollment" do
      expect(family.is_under_shop_open_enrollment?).to be_falsey
    end

    it "should have no current shop eligible open enrollments" do
      expect(family.current_shop_eligible_open_enrollments).to eq []
    end

    it "should not be in ivl open enrollment" do
      expect(family.is_under_ivl_open_enrollment?).to be_falsey
    end

    it "should have no current ivl eligible open enrollments" do
      expect(family.current_ivl_eligible_open_enrollments).to eq []
    end
  end

  context "one shop open enrollment period" do
    let!(:benefit_group) do
      bg = FactoryGirl.create(:benefit_group)
      py = bg.plan_year
      py.open_enrollment_start_on = TimeKeeper.date_of_record - 5.days
      py.open_enrollment_end_on = TimeKeeper.date_of_record + 5.days
      py.aasm_state = "published"
      py.save
      bg
    end
    let(:plan_year) { benefit_group.plan_year }
    let(:employer_profile) { plan_year.employer_profile }
    let!(:employee_role) { FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile) }
    let!(:census_employee) do
      ce = FactoryGirl.create(:census_employee,
        first_name: person.first_name,
        last_name: person.last_name,
        dob: person.dob,
        gender: person.gender,
        hired_on: TimeKeeper.date_of_record - 5.years,
        ssn: person.ssn,
        address: person.addresses.first,
        email: person.emails.first,
        employer_profile: employer_profile
      )
      employee_role.census_employee = ce
      employee_role.save
      ce
    end
    let!(:benefit_group_assignment) { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    it "should be in open enrollment" do
      expect(family.is_under_open_enrollment?).to be_truthy
    end

    it "should have one current eligible open enrollments" do
      expect(family.current_eligible_open_enrollments.count).to eq 1
    end

    it "should be in shop open enrollment" do
      expect(family.is_under_shop_open_enrollment?).to be_truthy
    end

    it "should have one current shop eligible open enrollments" do
      expect(family.current_shop_eligible_open_enrollments.count).to eq 1
    end

    it "should not be in ivl open enrollment" do
      expect(family.is_under_ivl_open_enrollment?).to be_falsey
    end

    it "should have no current ivl eligible open enrollments" do
      expect(family.current_ivl_eligible_open_enrollments.count).to eq 0
    end
  end

  context "multiple shop open enrollment periods" do
    let!(:benefit_group) do
      bg = FactoryGirl.create(:benefit_group)
      py = bg.plan_year
      py.open_enrollment_start_on = TimeKeeper.date_of_record - 5.days
      py.open_enrollment_end_on = TimeKeeper.date_of_record + 5.days
      py.aasm_state = "published"
      py.save
      bg
    end
    let(:plan_year) { benefit_group.plan_year }
    let(:employer_profile) { plan_year.employer_profile }
    let!(:employee_role) { FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile) }
    let!(:census_employee) do
      ce = FactoryGirl.create(:census_employee,
        first_name: person.first_name,
        last_name: person.last_name,
        dob: person.dob,
        gender: person.gender,
        hired_on: TimeKeeper.date_of_record - 5.years,
        ssn: person.ssn,
        address: person.addresses.first,
        email: person.emails.first,
        employer_profile: employer_profile
      )
      employee_role.census_employee = ce
      employee_role.save
      ce
    end
    let!(:benefit_group_assignment) { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    let!(:benefit_group2) do
      bg = FactoryGirl.create(:benefit_group)
      py = bg.plan_year
      py.open_enrollment_start_on = TimeKeeper.date_of_record - 5.days
      py.open_enrollment_end_on = TimeKeeper.date_of_record + 5.days
      py.aasm_state = "published"
      py.save
      bg
    end
    let(:plan_year2) { benefit_group2.plan_year }
    let(:employer_profile2) { plan_year2.employer_profile }
    let!(:employee_role2) { FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile2) }
    let!(:census_employee2) do
      ce = FactoryGirl.create(:census_employee,
        first_name: person.first_name,
        last_name: person.last_name,
        dob: person.dob,
        gender: person.gender,
        hired_on: TimeKeeper.date_of_record - 5.years,
        ssn: person.ssn,
        address: person.addresses.first,
        email: person.emails.first,
        employer_profile: employer_profile2
      )
      employee_role2.census_employee = ce
      employee_role2.save
      ce
    end
    let!(:benefit_group_assignment2) { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group2, census_employee: census_employee2)}

    it "should be in open enrollment" do
      expect(family.is_under_open_enrollment?).to be_truthy
    end

    it "should have two current eligible open enrollments" do
      expect(family.current_eligible_open_enrollments.count).to eq 2
    end

    it "should be in shop open enrollment" do
      expect(family.is_under_shop_open_enrollment?).to be_truthy
    end

    it "should have two current shop eligible open enrollments" do
      expect(family.current_shop_eligible_open_enrollments.count).to eq 2
    end

    it "should not be in ivl open enrollment" do
      expect(family.is_under_ivl_open_enrollment?).to be_falsey
    end

    it "should have no current ivl eligible open enrollments" do
      expect(family.current_ivl_eligible_open_enrollments.count).to eq 0
    end
  end

  context "one ivl open enrollment period" do
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }

    it "should be in open enrollment" do
      expect(family.is_under_open_enrollment?).to be_truthy
    end

    it "should have one current eligible open enrollments" do
      expect(family.current_eligible_open_enrollments.count).to eq 1
    end

    it "should not be in shop open enrollment" do
      expect(family.is_under_shop_open_enrollment?).to be_falsey
    end

    it "should have no current shop eligible open enrollments" do
      expect(family.current_shop_eligible_open_enrollments.count).to eq 0
    end

    it "should be in ivl open enrollment" do
      expect(family.is_under_ivl_open_enrollment?).to be_truthy
    end

    it "should have one current ivl eligible open enrollments" do
      expect(family.current_ivl_eligible_open_enrollments.count).to eq 1
    end
  end

  context "one shop and one ivl open enrollment period" do
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }

    let!(:benefit_group) do
      bg = FactoryGirl.create(:benefit_group)
      py = bg.plan_year
      py.open_enrollment_start_on = TimeKeeper.date_of_record - 5.days
      py.open_enrollment_end_on = TimeKeeper.date_of_record + 5.days
      py.aasm_state = "published"
      py.save
      bg
    end
    let(:plan_year) { benefit_group.plan_year }
    let(:employer_profile) { plan_year.employer_profile }
    let!(:employee_role) { FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile) }
    let!(:census_employee) do
      ce = FactoryGirl.create(:census_employee,
        first_name: person.first_name,
        last_name: person.last_name,
        dob: person.dob,
        gender: person.gender,
        hired_on: TimeKeeper.date_of_record - 5.years,
        ssn: person.ssn,
        address: person.addresses.first,
        email: person.emails.first,
        employer_profile: employer_profile
      )
      employee_role.census_employee = ce
      employee_role.save
      ce
    end
    let!(:benefit_group_assignment) { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }

    it "should be in open enrollment" do
      expect(family.is_under_open_enrollment?).to be_truthy
    end

    it "should have two current eligible open enrollments" do
      expect(family.current_eligible_open_enrollments.count).to eq 2
    end

    it "should be in shop open enrollment" do
      expect(family.is_under_shop_open_enrollment?).to be_truthy
    end

    it "should have one current shop eligible open enrollments" do
      expect(family.current_shop_eligible_open_enrollments.count).to eq 1
    end

    it "should be in ivl open enrollment" do
      expect(family.is_under_ivl_open_enrollment?).to be_truthy
    end

    it "should have one current ivl eligible open enrollments" do
      expect(family.current_ivl_eligible_open_enrollments.count).to eq 1
    end
  end

  context "multiple shop and one ivl open enrollment periods" do
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }

    let!(:benefit_group) do
      bg = FactoryGirl.create(:benefit_group)
      py = bg.plan_year
      py.open_enrollment_start_on = TimeKeeper.date_of_record - 5.days
      py.open_enrollment_end_on = TimeKeeper.date_of_record + 5.days
      py.aasm_state = "published"
      py.save
      bg
    end
    let(:plan_year) { benefit_group.plan_year }
    let(:employer_profile) { plan_year.employer_profile }
    let!(:employee_role) { FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile) }
    let!(:census_employee) do
      ce = FactoryGirl.create(:census_employee,
        first_name: person.first_name,
        last_name: person.last_name,
        dob: person.dob,
        gender: person.gender,
        hired_on: TimeKeeper.date_of_record - 5.years,
        ssn: person.ssn,
        address: person.addresses.first,
        email: person.emails.first,
        employer_profile: employer_profile
      )
      employee_role.census_employee = ce
      employee_role.save
      ce
    end
    let!(:benefit_group_assignment) { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee)}

    let!(:benefit_group2) do
      bg = FactoryGirl.create(:benefit_group)
      py = bg.plan_year
      py.open_enrollment_start_on = TimeKeeper.date_of_record - 5.days
      py.open_enrollment_end_on = TimeKeeper.date_of_record + 5.days
      py.aasm_state = "published"
      py.save
      bg
    end
    let(:plan_year2) { benefit_group2.plan_year }
    let(:employer_profile2) { plan_year2.employer_profile }
    let!(:employee_role2) { FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile2) }
    let!(:census_employee2) do
      ce = FactoryGirl.create(:census_employee,
        first_name: person.first_name,
        last_name: person.last_name,
        dob: person.dob,
        gender: person.gender,
        hired_on: TimeKeeper.date_of_record - 5.years,
        ssn: person.ssn,
        address: person.addresses.first,
        email: person.emails.first,
        employer_profile: employer_profile2
      )
      employee_role2.census_employee = ce
      employee_role2.save
      ce
    end
    let!(:benefit_group_assignment2) { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group2, census_employee: census_employee2)}

    it "should be in open enrollment" do
      expect(family.is_under_open_enrollment?).to be_truthy
    end

    it "should have three current eligible open enrollments" do
      expect(family.current_eligible_open_enrollments.count).to eq 3
    end

    it "should be in shop open enrollment" do
      expect(family.is_under_shop_open_enrollment?).to be_truthy
    end

    it "should have two current shop eligible open enrollments" do
      expect(family.current_shop_eligible_open_enrollments.count).to eq 2
    end

    it "should be in ivl open enrollment" do
      expect(family.is_under_ivl_open_enrollment?).to be_truthy
    end

    it "should have one current ivl eligible open enrollments" do
      expect(family.current_ivl_eligible_open_enrollments.count).to eq 1
    end
  end
end

describe Family, "is_blocked_by_qle_and_assistance" do
  let(:qle) {FactoryGirl.build(:qualifying_life_event_kind)}
  let(:family) {Family.new}
  let(:household) {double(latest_active_tax_household: double(latest_eligibility_determination: eligibility_determination))}
  let(:eligibility_determination) {double(max_aptc: 0)}

  it "return false without parameters" do
    expect(family.is_blocked_by_qle_and_assistance?()).to eq false
    expect(family.is_blocked_by_qle_and_assistance?(qle)).to eq false
  end

  it "return true when status is aptc_block" do
    family.status = "aptc_block"
    expect(family.is_blocked_by_qle_and_assistance?(nil, "abc")).to eq true
  end

  it "return false when status is aptc_block" do
    family.status = "aptc_unblock"
    expect(family.is_blocked_by_qle_and_assistance?(nil, "abc")).to eq false
  end

  #context "when max_aptc greater than 0" do
  #  before :each do
  #    allow(family).to receive(:latest_household).and_return household
  #    allow(eligibility_determination).to receive(:max_aptc).and_return 100
  #  end

  #  it "return false when qle is not individual" do
  #    allow(qle).to receive(:individual?).and_return false
  #    expect(family.is_blocked_by_qle_and_assistance?(qle, "abc")).to eq false
  #  end

  #  it "return false when qle is not family_structure_changed" do
  #    allow(qle).to receive(:individual?).and_return true
  #    allow(qle).to receive(:family_structure_changed?).and_return false
  #    expect(family.is_blocked_by_qle_and_assistance?(qle, "abc")).to eq false
  #  end

  #  it "return true" do
  #    allow(qle).to receive(:individual?).and_return true
  #    allow(qle).to receive(:family_structure_changed?).and_return true
  #    expect(family.is_blocked_by_qle_and_assistance?(qle, "abc")).to eq true
  #  end
  #end

  #it "return false when max_aptc is 0" do
  #  allow(family).to receive(:latest_household).and_return household
  #  allow(eligibility_determination).to receive(:max_aptc).and_return 0
  #  expect(family.is_blocked_by_qle_and_assistance?(qle, "abc")).to eq false
  #end
end

describe Family, "aptc_blocked?" do
  let(:family) {Family.new}

  it "return false" do
    expect(family.aptc_blocked?).to eq false
  end

  it "return true" do
    family.status = "aptc_block"
    expect(family.aptc_blocked?).to eq true
  end
end

describe Family, "update_aptc_block_status" do
  let(:family) {Family.new}
  let(:eligibility_determination) {double(max_aptc: 0)}
  #let(:household) {double(latest_active_tax_household: double(latest_eligibility_determination: eligibility_determination))}
  let(:household) { double(latest_active_tax_household: double(eligibility_determinations: [eligibility_determination])) }

  it "set aptc_block" do
    allow(family).to receive(:latest_household).and_return household
    #allow(eligibility_determination).to receive(:max_aptc).and_return 100
    #allow(family).to receive(:is_under_special_enrollment_period?).and_return true
    allow(family).to receive(:has_aptc_hbx_enrollment?).and_return true
    family.update_aptc_block_status
    expect(family.status).to eq "aptc_block"
  end
end

describe Family, 'coverage_waived?' do
  let(:family) {Family.new}
  let(:household) {double}
  let(:hbx_enrollment) {HbxEnrollment.new}
  let(:hbx_enrollments) { double }

  # def coverage_waived?
  #   latest_household.hbx_enrollments.any? and latest_household.hbx_enrollments.waived.any?
  # end

  before :each do
    allow(hbx_enrollments).to receive(:any?).and_return(true)
    allow(household).to receive(:hbx_enrollments).and_return(hbx_enrollments)
    allow(hbx_enrollments).to receive(:waived).and_return([])
    allow(family).to receive(:latest_household).and_return household
  end

  it "return false without hbx_enrollments" do
    allow(household).to receive(:hbx_enrollments).and_return []
    expect(family.coverage_waived?).to eq false
  end

  it "return false with hbx_enrollments" do
    expect(family.coverage_waived?).to eq false
  end

  it "return true" do
    allow(hbx_enrollments).to receive(:waived).and_return([hbx_enrollment])
    expect(family.coverage_waived?).to eq true
  end
end

describe Family, "with 2 households a person and 2 extended family members", :dbclean => :after_each do
  let(:family) { FactoryGirl.build(:family) }
  let(:primary) { FactoryGirl.create(:person) }
  let(:family_member_person_1) { FactoryGirl.create(:person) }
  let(:family_member_person_2) { FactoryGirl.create(:person) }

  before(:each) do
    f_id = family.id
    family.add_family_member(primary, is_primary_applicant: true)
    family.relate_new_member(family_member_person_1, "unknown")
    family.relate_new_member(family_member_person_2, "unknown")
    family.save!
  end

  it "should have the extended family member in the extended coverage household" do
    immediate_coverage_members = family.active_household.immediate_family_coverage_household.coverage_household_members
    extended_coverage_members = family.active_household.extended_family_coverage_household.coverage_household_members
    expect(immediate_coverage_members.count).to eq 1
    expect(extended_coverage_members.count).to eq 2
  end

  describe "when the one extended family member is moved to spouse" do

    before :each do
      family.relate_new_member(family_member_person_1, "child")
      family.save!
    end

    it "should have the extended family member in the primary coverage household" do
      immediate_coverage_members = family.active_household.immediate_family_coverage_household.coverage_household_members
      expect(immediate_coverage_members.length).to eq 2
    end

    it "should not have the extended family member in the extended coverage household" do
      extended_coverage_members = family.active_household.extended_family_coverage_household.coverage_household_members
      expect(extended_coverage_members.length).to eq 1
    end
  end
end

describe Family, "given a primary applicant and a dependent", dbclean: :after_each do
  let(:person) { FactoryGirl.create(:person)}
  let(:person_two) { FactoryGirl.create(:person) }
  let(:family_member_dependent) { FactoryGirl.build(:family_member, person: person_two, family: family)}
  let(:family) { FactoryGirl.build(:family, :with_primary_family_member, person: person)}

  it "should not build the consumer role for the dependents if primary do not have a consumer role" do
    expect(family_member_dependent.person.consumer_role).to eq nil
    family_member_dependent.family.check_for_consumer_role
    expect(family_member_dependent.person.consumer_role).to eq nil
  end
 
  it "should build the consumer role for the dependents when primary has a consumer role" do
    person.consumer_role = FactoryGirl.create(:consumer_role)
    person.save
    expect(family_member_dependent.person.consumer_role).to eq nil
    family_member_dependent.family.check_for_consumer_role
    expect(family_member_dependent.person.consumer_role).not_to eq nil
  end

  it "should return the existing consumer roles if dependents already have a consumer role" do
    person.consumer_role = FactoryGirl.create(:consumer_role)
    person.save
    cr = FactoryGirl.create(:consumer_role)
    person_two.consumer_role = cr
    person_two.save
    expect(family_member_dependent.person.consumer_role).to eq cr
    family_member_dependent.family.check_for_consumer_role
    expect(family_member_dependent.person.consumer_role).to eq cr
  end  
end
