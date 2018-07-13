require "rails_helper"

describe HbxEnrollment, "given a combination of dependents for a shop enrollment" do

  shared_examples_for "an hbx_enrollment determining its composite rating tier" do |relationships, expected_tier|

    let(:employee_member) do
      HbxEnrollmentMember.new(:is_subscriber => true)
    end

    let(:dependent_members) do
      relationships.map do |rel|
        record = HbxEnrollmentMember.new(:is_subscriber => false)
        allow(record).to receive(:primary_relationship).and_return(rel)
        record
      end
    end

    subject { 
      HbxEnrollment.new({
        :kind => "employer_sponsored",
        :hbx_enrollment_members => [employee_member] + dependent_members
      })    
    }

    it "has a composite rating tier of #{expected_tier}, for #{relationships.join(', ')}" do
      expect(subject.composite_rating_tier).to eq expected_tier
    end
  end

  it_behaves_like "an hbx_enrollment determining its composite rating tier", [], CompositeRatingTier::EMPLOYEE_ONLY
  it_behaves_like "an hbx_enrollment determining its composite rating tier", ["life_partner"], CompositeRatingTier::EMPLOYEE_AND_SPOUSE
  it_behaves_like "an hbx_enrollment determining its composite rating tier", ["spouse"], CompositeRatingTier::EMPLOYEE_AND_SPOUSE
  it_behaves_like "an hbx_enrollment determining its composite rating tier", ["spouse","child"], CompositeRatingTier::FAMILY
  it_behaves_like "an hbx_enrollment determining its composite rating tier", ["child", "spouse"], CompositeRatingTier::FAMILY
  it_behaves_like "an hbx_enrollment determining its composite rating tier", ["child", "life_partner"], CompositeRatingTier::FAMILY
  it_behaves_like "an hbx_enrollment determining its composite rating tier", ["sibling"], CompositeRatingTier::EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS
  it_behaves_like "an hbx_enrollment determining its composite rating tier", ["child"], CompositeRatingTier::EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS
  it_behaves_like "an hbx_enrollment determining its composite rating tier", ["child", "sibling"], CompositeRatingTier::EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS
  it_behaves_like "an hbx_enrollment determining its composite rating tier", ["child", "adopted_child"], CompositeRatingTier::EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS
end
