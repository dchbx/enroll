require 'rails_helper'

module BenefitSponsors

  RSpec.describe Organizations::OrganizationForms::ProfileForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Organizations::OrganizationForms::ProfileForm }
    let(:model_attributes) { [:id, :market_kind, :is_benefit_sponsorship_eligible,:corporate_npn,:languages_spoken,:working_hours,:accept_new_clients,:home_page,:contact_method,:market_kind_options,:grouped_sic_code_options,:language_options,:contact_method_options,:profile_type,:sic_code,:inbox,:parent,:office_locations] }

    describe "profile form" do

      context "model attributes" do
        it "should have all the attributes" do
          model_attributes.each do |key|
            expect(subject.new.attributes.has_key?(key)).to be_truthy
          end
        end

        it 'instantiates a new Profile Form' do
          expect(subject.new).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::ProfileForm)
        end
      end

      context "profile_type == benefit_sponsor" do

        let(:params) {
          {
            "profile_type"=>"benefit_sponsor",
            "sic_code"=>"0279",
            "office_locations_attributes"=>
                {"0"=>
                  {
                    "address_attributes"=>{"address_1"=>"ghsdcvgsv", "kind"=>"primary", "address_2"=>"sb sb", "city"=>"vsgsd", "state"=>"DC", "zip"=>"65234", "county"=>"Barnstable"},
                    "phone_attributes"=>{"kind"=>"phone main", "area_code"=>"564", "number"=>"5646543", "extension"=>""}
                  }
                }
          }
        }

        it "new form should be valid" do
          new_form = subject.new(params)
          new_form.validate
          expect(new_form).to be_valid
        end

        it ".is_employer_profile?" do
          new_form = subject.new params
          expect(new_form.is_employer_profile?).to eq true
        end

        it ".is_broker_profile??" do
          new_form = subject.new params
          expect(new_form.is_broker_profile?).to eq false
        end
      end

      context "profile_type == broker_agency" do

        let(:params) {
          {
            "profile_type"=>"broker_agency",
            "market_kind"=>"shop",
            "languages_spoken"=>["", "en"],
            "working_hours"=>"1",
            "accept_new_clients"=>"1",
            "ach_account_number"=>"8723456735443",
            "ach_routing_number"=>"678678678",
            "ach_routing_number_confirmation"=>"678678678",
            "office_locations_attributes"=>
                  {"0"=>
                    {
                      "address_attributes"=>{"address_1"=>"jhsdbhjsdb", "kind"=>"primary", "address_2"=>"jhscvdhs", "city"=>"hgvchgsv", "state"=>"DC", "zip"=>"27452"},
                      "phone_attributes"=>{"kind"=>"phone main", "area_code"=>"736", "number"=>"6543565", "extension"=>""}
                    }
                  }
          }
        }

        it "new form should be valid" do
          new_form = subject.new params
          new_form.validate
          expect(new_form).to be_valid
        end

        it "new form should not be valid with out market_kind" do
          new_form = subject.new params.except!("market_kind")
          new_form.validate
          expect(new_form).to_not be_valid
        end

        it ".is_employer_profile?" do
          new_form = subject.new params
          expect(new_form.is_employer_profile?).to eq false
        end

        it ".is_broker_profile??" do
          new_form = subject.new params
          expect(new_form.is_broker_profile?).to eq true
        end
      end
    end
  end
end