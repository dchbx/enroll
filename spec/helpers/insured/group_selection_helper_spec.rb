require "rails_helper"

RSpec.describe Insured::GroupSelectionHelper, :type => :helper do
  let(:subject)  { Class.new { extend Insured::GroupSelectionHelper } }

  describe "#can shop individual" do
    let(:person) { FactoryGirl.create(:person) }

    it "should not have an active consumer role" do
      expect(subject.can_shop_individual?(person)).not_to be_truthy
    end

    context "with active consumer role" do
      let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
      it "should have active consumer role" do
        expect(subject.can_shop_individual?(person)).to be_truthy
      end

    end
  end

  describe "#can shop shop" do
    let(:person) { FactoryGirl.create(:person) }

    it "should not have an active employee role" do
        expect(subject.can_shop_shop?(person)).not_to be_truthy
    end
    context "with active employee role" do
      let(:person) { FactoryGirl.create(:person, :with_employee_role) }
      before do
        allow(person).to receive(:has_active_employee_role?).and_return(true)
      end

      it "should have active employee role but no benefit group" do
        expect(subject.can_shop_shop?(person)).not_to be_truthy
      end

    end

    context "with active employee role and benefit group" do
      let(:person) { FactoryGirl.create(:person, :with_employee_role) }
      before do
        allow(person).to receive(:has_active_employee_role?).and_return(true)
        allow(person).to receive(:has_employer_benefits?).and_return(true)
      end

      it "should have active employee role and benefit group" do
        expect(subject.can_shop_shop?(person)).to be_truthy
      end
    end

  end

  describe "#can shop both" do
    let(:person) { FactoryGirl.create(:person) }
    context "with active consumer role" do
      let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_employee_role) }
      before do
        allow(person).to receive(:has_active_employee_role?).and_return(true)
      end
      it "should have both active consumer and employee role" do
        expect(subject.can_shop_both_markets?(person)).not_to be_truthy
      end
    end

    context "with active consumer role" do
      let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_employee_role) }
      before do
        allow(person).to receive(:has_active_employee_role?).and_return(true)
        allow(person).to receive(:has_employer_benefits?).and_return(true)
      end
      it "should have both active consumer and employee role" do
        expect(subject.can_shop_both_markets?(person)).to be_truthy
      end
    end

  end

  describe "#health_relationship_benefits" do

    context "active/renewal health benefit group offered relationships" do
      let(:employee_role){FactoryGirl.build(:employee_role)}
      let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group) }
      let!(:active_benefit_group) { FactoryGirl.create(:benefit_group)}

      let(:relationship_benefits) do
        [
            RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
            RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75),
            RelationshipBenefit.new(offered: true, relationship: :child_under_26, premium_pct: 50)
        ]
      end

      it "should return offered relationships of active health benefit group" do
        allow(employee_role).to receive_message_chain(:census_employee, :renewal_published_benefit_group).and_return(active_benefit_group)
        allow(active_benefit_group).to receive_message_chain(:relationship_benefits).and_return(relationship_benefits)
        expect(subject.health_relationship_benefits(employee_role)).to eq ["employee", "spouse", "child_under_26"]
      end

      it "should return offered relationships of renewal health benefit group" do
        allow(employee_role).to receive_message_chain(:census_employee, :renewal_published_benefit_group).and_return(renewal_benefit_group)
        allow(renewal_benefit_group).to receive_message_chain(:relationship_benefits).and_return(relationship_benefits)
        expect(subject.health_relationship_benefits(employee_role)).to eq ["employee", "spouse", "child_under_26"]
      end
    end
  end

  describe "#dental_relationship_benefits" do

    context "active/renewal dental benefit group offered relationships" do
      let(:employee_role){FactoryGirl.build(:employee_role)}
      let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group) }
      let!(:active_benefit_group) { FactoryGirl.create(:benefit_group)}

      let(:dental_relationship_benefits) do
        [
            RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
            RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75),
            RelationshipBenefit.new(offered: true, relationship: :child_under_26, premium_pct: 50)
        ]
      end

      it "should return offered relationships of active dental benefit group" do
        allow(employee_role).to receive_message_chain(:census_employee, :renewal_published_benefit_group).and_return(active_benefit_group)
        allow(active_benefit_group).to receive_message_chain(:dental_relationship_benefits).and_return(dental_relationship_benefits)
        expect(subject.dental_relationship_benefits(employee_role)).to eq ["employee", "spouse", "child_under_26"]
      end

      it "should return offered relationships of renewal dental benefit group" do
        allow(employee_role).to receive_message_chain(:census_employee, :renewal_published_benefit_group).and_return(renewal_benefit_group)
        allow(renewal_benefit_group).to receive_message_chain(:dental_relationship_benefits).and_return(dental_relationship_benefits)
        expect(subject.dental_relationship_benefits(employee_role)).to eq ["employee", "spouse", "child_under_26"]
      end
    end
  end


  describe "#selected_enrollment" do

    context "selelcting the enrollment" do
      let(:person) { FactoryGirl.create(:person) }
      let(:employee_role) { FactoryGirl.create(:employee_role, person: person, employer_profile: organization.employer_profile, census_employee_id: census_employee.id)}
      let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
      let(:organization) { FactoryGirl.create(:organization, :with_active_and_renewal_plan_years)}
      let(:qle_kind) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date) }
      let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: organization.employer_profile)}
      let(:sep){
        sep = family.special_enrollment_periods.new
        sep.effective_on_kind = 'date_of_event'
        sep.qualifying_life_event_kind= qle_kind
        sep.qle_on= TimeKeeper.date_of_record - 7.days
        sep.save
        sep
      }
      let(:active_enrollment) { FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         kind: "employer_sponsored",
                         employee_role_id: employee_role.id,
                         enrollment_kind: "special_enrollment",
                         aasm_state: 'coverage_selected'
      )}
      let(:renewal_enrollment) { FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         kind: "employer_sponsored",
                         employee_role_id: employee_role.id,
                         enrollment_kind: "special_enrollment",
                         aasm_state: 'renewing_coverage_selected'
      )}

      before do
        allow(family).to receive(:current_sep).and_return sep
        active_benefit_group = organization.employer_profile.plan_years.where(aasm_state: "active").first.benefit_groups.first
        renewal_benefit_group = organization.employer_profile.plan_years.where(aasm_state: "renewing_enrolling").first.benefit_groups.first
        active_enrollment.update_attribute(:benefit_group_id, active_benefit_group.id)
        renewal_enrollment.update_attribute(:benefit_group_id, renewal_benefit_group.id)
      end

      it "should return active enrollment if the coverage effective on covers active plan year" do
        expect(Insured::GroupSelectionHelper.selected_enrollment(family, employee_role)).to eq active_enrollment
      end

      it "should return renewal enrollment if the coverage effective on covers renewal plan year" do
        renewal_plan_year = organization.employer_profile.plan_years.where(aasm_state: "renewing_enrolling").first
        sep.update_attribute(:effective_on, renewal_plan_year.start_on + 2.days)
        expect(Insured::GroupSelectionHelper.selected_enrollment(family, employee_role)).to eq renewal_enrollment
      end

      context 'it should not return any enrollment' do

        before do
          allow(employee_role.census_employee).to receive(:active_benefit_group).and_return nil
          allow(employee_role.census_employee).to receive(:renewal_published_benefit_group).and_return nil
        end

        it "should not return active enrollment although if the coverage effective on covers active plan year & if not belongs to the assigned benefit group" do
          expect(Insured::GroupSelectionHelper.selected_enrollment(family, employee_role)).to eq nil
        end

        it "should not return renewal enrollment although if the coverage effective on covers renewal plan year & if not belongs to the assigned benefit group" do
          renewal_plan_year = organization.employer_profile.plan_years.where(aasm_state: "renewing_enrolling").first
          sep.update_attribute(:effective_on, renewal_plan_year.start_on + 2.days)
          expect(Insured::GroupSelectionHelper.selected_enrollment(family, employee_role)).to eq nil
        end
      end
    end
  end

  describe "#coverage_tr_class" do
    context "with is_covarage and is_ineligible_for_individual as nil" do
      let(:coverage_tr_class) {subject.coverage_tr_class(nil, nil)}
      it 'returns a blank class' do
        expect(coverage_tr_class).to be_blank
      end
    end

    context "with is_covarage as nil and is_ineligible_for_individual as false" do
      let(:coverage_tr_class) {subject.coverage_tr_class(nil, false)}
      it 'returns a blank class' do
        expect(coverage_tr_class).to be_blank
      end
    end

    context "with is_covarage as false and is_ineligible_for_individual as false" do
      let(:coverage_tr_class) {subject.coverage_tr_class(nil, false)}
      it 'returns a blank class' do
        expect(coverage_tr_class).to be_blank
      end
    end

    context "with is_covarage as true and is_ineligible_for_individual as false" do
      let(:coverage_tr_class) {subject.coverage_tr_class(true, false)}
      it 'returns the expected class' do
        expect(coverage_tr_class).to be_blank
      end
    end

    context "with is_covarage as true and is_ineligible_for_individual as true" do
      let(:coverage_tr_class) {subject.coverage_tr_class(true, true)}
      let(:expected_tr_class) {' ineligible_row_for_ivl'}
      it 'returns the expected class' do
        expect(coverage_tr_class).to eq expected_tr_class
      end
    end

    context "with is_covarage as false and is_ineligible_for_individual as true" do
      let(:coverage_tr_class) {subject.coverage_tr_class(false, true)}
      let(:expected_tr_class) {' ineligible_row ineligible_row_for_ivl'}
      it 'returns the expected class' do
        expect(coverage_tr_class).to eq expected_tr_class
      end
    end
  end

  describe "#coverage_td_class" do
    context "is_ineligible_for_individual as nil" do
      let(:coverage_td_class) {subject.coverage_td_class(nil)}
      it 'returns a blank class' do
        expect(coverage_td_class).to be_blank
      end
    end

    context "is_ineligible_for_individual as false" do
      let(:coverage_td_class) {subject.coverage_td_class(false)}
      it 'returns a blank class' do
        expect(coverage_td_class).to be_blank
      end
    end

    context "with is_ineligible_for_individual as true" do
      let(:coverage_td_class) {subject.coverage_td_class(true)}
      let(:expected_tr_class) {' ineligible_detail_for_ivl'}
      it 'returns the expected class' do
        expect(coverage_td_class).to eq expected_tr_class
      end
    end
  end

  describe "#ineligible_due_to_non_dc_address" do
    context "with family_member as nil" do
      let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(nil)}
      it 'returns nil' do
        expect(ineligible_due_to_non_dc_address).to be_nil
      end
    end

    context "with primary applicant as family member" do
      let(:family_member) {double('family_member')}
      let(:person) {double('person')}
      before {allow(family_member).to receive(:is_primary_applicant).and_return(true)}
      context 'who has active employee and consumer role' do
        before do
          allow(person).to receive(:has_active_consumer_role?).and_return(true)
          allow(person).to receive(:has_active_employee_role?).and_return(true)
        end

        context 'who is a dc resident' do
          before do
            allow(person).to receive(:no_dc_address).and_return(nil)
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns false' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end

        context 'who is not a dc resident' do
          before do
            allow(person).to receive(:no_dc_address).and_return(true)
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns true' do
            expect(ineligible_due_to_non_dc_address).to be_truthy
          end
        end
      end

      context 'who doesnt have active employee but has active consumer role' do
        before do
          allow(person).to receive(:has_active_consumer_role?).and_return(true)
          allow(person).to receive(:has_active_employee_role?).and_return(false)
        end

        context 'who is a dc resident' do
          before do
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns false' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end

        context 'who is not a dc resident' do
          before do
            allow(person).to receive(:no_dc_address).and_return(true)
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns true' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end
      end

      context 'who has have active employee but doesnt have active consumer role' do
        before do
          allow(person).to receive(:has_active_consumer_role?).and_return(false)
          allow(person).to receive(:has_active_employee_role?).and_return(true)
        end

        context 'who is a dc resident' do
          before do
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns false' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end

        context 'who is not a dc resident' do
          before do
            allow(person).to receive(:no_dc_address).and_return(true)
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns true' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end
      end

      context 'who doesnt have active employee nor active consumer role' do
        before do
          allow(person).to receive(:has_active_consumer_role?).and_return(false)
          allow(person).to receive(:has_active_employee_role?).and_return(false)
        end

        context 'who is a dc resident' do
          before do
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns false' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end

        context 'who is not a dc resident' do
          before do
            allow(person).to receive(:no_dc_address).and_return(true)
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns true' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end
      end
    end

    context "with non primary applicant as family member" do
      let(:family_member) {double('family_member')}
      let(:person) {double('person')}
      before {allow(family_member).to receive(:is_primary_applicant).and_return(false)}
      context 'who has active employee and consumer role' do
        before do
          allow(person).to receive(:has_active_consumer_role?).and_return(true)
          allow(person).to receive(:has_active_employee_role?).and_return(true)
        end

        context 'who is a dc resident' do
          before do
            allow(person).to receive(:no_dc_address).and_return(nil)
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns false' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end

        context 'who is not a dc resident' do
          before do
            allow(person).to receive(:no_dc_address).and_return(true)
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns true' do
            expect(ineligible_due_to_non_dc_address).to be_truthy
          end
        end
      end

      context 'who doesnt have active employee but has active consumer role' do
        before do
          allow(person).to receive(:has_active_consumer_role?).and_return(true)
          allow(person).to receive(:has_active_employee_role?).and_return(false)
        end

        context 'who is a dc resident' do
          before do
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns false' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end

        context 'who is not a dc resident' do
          before do
            allow(person).to receive(:no_dc_address).and_return(true)
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns true' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end
      end

      context 'who has have active employee but doesnt have active consumer role' do
        before do
          allow(person).to receive(:has_active_consumer_role?).and_return(false)
          allow(person).to receive(:has_active_employee_role?).and_return(true)
        end

        context 'who is a dc resident' do
          before do
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns false' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end

        context 'who is not a dc resident' do
          before do
            allow(person).to receive(:no_dc_address).and_return(true)
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns true' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end
      end

      context 'who doesnt have active employee nor active consumer role' do
        before do
          allow(person).to receive(:has_active_consumer_role?).and_return(false)
          allow(person).to receive(:has_active_employee_role?).and_return(false)
        end

        context 'who is a dc resident' do
          before do
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns false' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end

        context 'who is not a dc resident' do
          before do
            allow(person).to receive(:no_dc_address).and_return(true)
            allow(family_member).to receive(:primary_applicant).and_return(person)
          end
          let(:ineligible_due_to_non_dc_address) {subject.ineligible_due_to_non_dc_address(family_member)}
          it 'returns true' do
            expect(ineligible_due_to_non_dc_address).to be_falsey
          end
        end
      end
    end
  end
end
