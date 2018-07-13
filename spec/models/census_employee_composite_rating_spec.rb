require "rails_helper"

describe CensusEmployee, "given a combination of dependents" do

  shared_examples_for "a census employee determining its composite rating tier" do |relationships, expected_tier|

    let(:census_dependents) do
      relationships.map do |rel|
        CensusDependent.new(:employee_relationship => rel) 
      end
    end

    subject { CensusEmployee.new(census_dependents: census_dependents) }

    it "has a composite rating tier of #{expected_tier}, for #{relationships.join(', ')}" do
      expect(subject.composite_rating_tier).to eq expected_tier
    end
  end

  it_behaves_like "a census employee determining its composite rating tier", [], CompositeRatingTier::EMPLOYEE_ONLY
  it_behaves_like "a census employee determining its composite rating tier", ["domestic_partner"], CompositeRatingTier::EMPLOYEE_AND_SPOUSE
  it_behaves_like "a census employee determining its composite rating tier", ["spouse"], CompositeRatingTier::EMPLOYEE_AND_SPOUSE
  it_behaves_like "a census employee determining its composite rating tier", ["spouse","child_26_and_over"], CompositeRatingTier::FAMILY
  it_behaves_like "a census employee determining its composite rating tier", ["child_26_and_over", "domestic_partner"], CompositeRatingTier::FAMILY
  it_behaves_like "a census employee determining its composite rating tier", ["child_26_and_over", "spouse"], CompositeRatingTier::FAMILY
  it_behaves_like "a census employee determining its composite rating tier", ["child_under_26"], CompositeRatingTier::EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS
  it_behaves_like "a census employee determining its composite rating tier", ["disabled_child_26_and_over"], CompositeRatingTier::EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS
  it_behaves_like "a census employee determining its composite rating tier", ["child_26_and_over", "child_under_26"], CompositeRatingTier::EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS
  it_behaves_like "a census employee determining its composite rating tier", ["disabled_child_26_and_over", "child_under_26"], CompositeRatingTier::EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS
end
