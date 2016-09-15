require "rails_helper"

RSpec.describe Insured::EmployeeRolesHelper, :type => :helper do
  describe "#calculate_age_by_dob" do
    context "return age by dob" do
      it "with now month less than dob month" do
        now = TimeKeeper.date_of_record
        dob = TimeKeeper.date_of_record - 10.years - 1.month
        expect(helper.calculate_age_by_dob(dob)).to eq 10
      end

      it "with now month more than dob month" do
        now = TimeKeeper.date_of_record
        dob = TimeKeeper.date_of_record - 10.years + 1.month
        expect(helper.calculate_age_by_dob(dob)).to eq 9
      end

      context "with now month equal dob month" do
        it "and now day less than dob day" do
          now = TimeKeeper.date_of_record
          dob = TimeKeeper.date_of_record - 10.years - 1.day
          expect(helper.calculate_age_by_dob(dob)).to eq 10
        end

        it "and now day more than dob day" do
          now = TimeKeeper.date_of_record
          dob = TimeKeeper.date_of_record - 10.years + 1.day
          expect(helper.calculate_age_by_dob(dob)).to eq 9
        end

        it "and now day equal dob day" do
          now = TimeKeeper.date_of_record
          dob = TimeKeeper.date_of_record - 10.years
          expect(helper.calculate_age_by_dob(dob)).to eq 10
        end
      end
    end
  end

  describe "#coverage_relationship_check" do
    let(:orb) {["employee", "spouse", "child_under_26"]}
    let(:spouse) { double(primary_relationship: "ex-spouse", is_disabled: false,
                           has_primary_caregiver: false , dob:  TimeKeeper.date_of_record ) }
    let(:domestic_partner) { double(primary_relationship: "life_partner") }
    let(:child) {double(primary_relationship: "ward",  is_disabled: false,
                           has_primary_caregiver: true , dob: TimeKeeper.date_of_record)}

    it "offered_relationship_benefits include the relationship of family_member" do
      expect(helper.coverage_relationship_check(orb, spouse)).to be_truthy
    end

    it "offered_relationship_benefits not include the relationship of family_member" do
      expect(helper.coverage_relationship_check(orb, domestic_partner)).to be_falsey
    end

    context "with child" do
      it "and age over 26" do
        allow(helper).to receive(:calculate_age_by_dob).and_return(30)
        expect(helper.coverage_relationship_check(orb, child)).to be_falsey
      end

      it "and age under 26" do
        allow(helper).to receive(:calculate_age_by_dob).and_return(10)
        expect(helper.coverage_relationship_check(orb, child)).to be_truthy
      end
    end
  end
end
