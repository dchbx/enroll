require 'rails_helper'

describe Family, "with 2 policies", :dbclean => :after_each do
  let(:family) { FactoryGirl.build(:family) }
  let(:primary) { FactoryGirl.create(:consumer_role) }
  let(:plan) { FactoryGirl.create(:plan) }
  let(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }
  let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }

  before :each do
    TimeKeeper.set_date_of_record_unprotected!(Date.new(2015, 12, 15))
    family.add_family_member(primary.person, is_primary_applicant: true)
    family.save!

    @hbx_enrollment_1 = HbxEnrollment.create_from(coverage_household: family.active_household.immediate_family_coverage_household, consumer_role: primary, benefit_package: benefit_package)
    @hbx_enrollment_2 = HbxEnrollment.create_from(coverage_household: family.active_household.immediate_family_coverage_household, consumer_role: primary, benefit_package: benefit_package)
    @id_for_1 = @hbx_enrollment_1.id
    @id_for_2 = @hbx_enrollment_2.id
    family.reload
  end

  after do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  describe "when the start dates on the second policy are changed" do
    let(:new_effective_on_date) { Date.new(2013,4,25) }

    before :each do
      @pol_1_effective_date = @hbx_enrollment_1.effective_on
      @hbx_enrollment_2.update_attributes!(:effective_on => new_effective_on_date)
      family.reload
      hh = family.active_household
      @first_enrollment = hh.hbx_enrollments.detect { |he| he.id == @id_for_1 }
      @second_enrollment = hh.hbx_enrollments.detect { |he| he.id == @id_for_2 }
    end

    it "should have the original effective on for the first policy" do

      expect(@first_enrollment.effective_on).to eq @pol_1_effective_date
    end

    it "should have the correct effective_on for the second policy" do
      expect(@second_enrollment.effective_on).to eq new_effective_on_date
    end
  end

  describe "when the start dates on the second policy are changed for the enrollment_member" do
    let(:new_effective_on_date) { Date.new(2013,4,25) }

    before :each do
      @pol_1_effective_date = @hbx_enrollment_1.hbx_enrollment_members.first.coverage_start_on
      @hbx_enrollment_2.hbx_enrollment_members.first.update_attributes!(:coverage_start_on => new_effective_on_date)
      family.reload
      hh = family.active_household
      @first_enrollment = hh.hbx_enrollments.detect { |he| he.id == @id_for_1 }
      @second_enrollment = hh.hbx_enrollments.detect { |he| he.id == @id_for_2 }
    end

    it "should have the original start_on for the first policy's enrollee" do
      expect(@first_enrollment.hbx_enrollment_members.first.coverage_start_on).to eq @pol_1_effective_date
    end

    it "should have the correct start_on for the second policy's enrollee" do
      expect(@second_enrollment.hbx_enrollment_members.first.coverage_start_on).to eq new_effective_on_date
    end
  end
end
