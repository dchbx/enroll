require 'rails_helper'

module SponsoredBenefits
  RSpec.describe CensusMembers::PlanDesignCensusEmployee, type: :model, dbclean: :after_each do


    # let(:employer_profile) { create(:sponsored_benefits_benefit_sponsorships_plan_design_employer_profile) }
    
    let(:first_name){ "Lynyrd" }
    let(:middle_name){ "Rattlesnake" }
    let(:last_name){ "Skynyrd" }
    let(:name_sfx){ "PhD" }
    let(:ssn){ "230987654" }
    let(:dob){ TimeKeeper.date_of_record - 31.years }
    let(:gender){ "male" }
    let(:hired_on){ TimeKeeper.date_of_record - 14.days }
    let(:is_business_owner){ false }
    let(:address) { Locations::Address.new(kind: "home", address_1: "221 R St, NW", city: "Washington", state: "DC", zip: "20001") }
    let(:autocomplete) { " lynyrd skynyrd" }

    let(:valid_params){
      {
        # employer_profile: employer_profile,
        first_name: first_name,
        middle_name: middle_name,
        last_name: last_name,
        name_sfx: name_sfx,
        ssn: ssn,
        dob: dob,
        gender: gender,
        hired_on: hired_on,
        is_business_owner: is_business_owner,
        address: address
      }
    }


    let!(:subject) { CensusMembers::PlanDesignCensusEmployee.new(valid_params) }

    context "given the minimal params" do

      it "builds a basic application" do
  
        expect(subject).to be_kind_of(SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee)
      end
    end
  end
end
