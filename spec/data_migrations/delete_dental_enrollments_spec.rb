require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "delete_dental_enrollments")

describe DeleteDentalEnrollment do
  describe "Delete dental enrollments" do
    subject { DeleteDentalEnrollment.new }

    context "a family with 2 dental and 2 health enrollments" do
      let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
      let(:dental_enrollment1) {FactoryGirl.create(:hbx_enrollment, :with_dental_coverage_kind, household: family.active_household)}
      let(:dental_enrollment2) {FactoryGirl.create(:hbx_enrollment, :with_dental_coverage_kind, household: family.active_household)}
      let(:health_enrollment1) {FactoryGirl.create(:hbx_enrollment,household: family.active_household)}
      let(:health_enrollment2) {FactoryGirl.create(:hbx_enrollment,household: family.active_household)}

      it "deletes the dentals" do
        expect(family.active_household.hbx_enrollments).to include dental_enrollment1
        expect(family.active_household.hbx_enrollments).to include dental_enrollment2
        expect(family.active_household.hbx_enrollments).to include health_enrollment1
        expect(family.active_household.hbx_enrollments).to include health_enrollment2
        family.primary_applicant.person.update_attribute(:hbx_id, "1234567890")
        expect(family.primary_applicant.person.hbx_id).to eq "1234567890"
        DeleteDentalEnrollment.migrate("1234567890")
        p = Person.where(hbx_id: "1234567890").first
        expect(p.primary_family.active_household.hbx_enrollments.where(coverage_kind: "health").size).to eq 2
        expect(p.primary_family.active_household.hbx_enrollments.where(coverage_kind: "dental").size).to eq 0
      end
    end
  end
end
