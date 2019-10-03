require "rails_helper"

RSpec.describe HbxEnrollmentSponsorEnrollmentCoverageReportCalculator, dbclean: :after_each do
  describe HbxEnrollmentSponsorEnrollmentCoverageReportCalculator::HbxEnrollmentRosterMapper do
    subject { HbxEnrollmentSponsorEnrollmentCoverageReportCalculator::HbxEnrollmentRosterMapper.new([enrollment.id], nil) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        :shop,
        :with_health_product,
        :coverage_selected,
        family: family)
    end

    it "generates a valid query" do
      found_the_enrollment = false
      subject.search_criteria([enrollment.id]).each do |rec|
        found_the_enrollment = true
        expect(rec['hbx_enrollment']['coverage_kind']).to eq "health"
      end
      expect(found_the_enrollment).to be_truthy
    end
  end
end
