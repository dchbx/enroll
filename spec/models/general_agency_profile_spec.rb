require 'rails_helper'

RSpec.describe GeneralAgencyProfile, dbclean: :after_each do
  it { should validate_presence_of :market_kind }
  it { should delegate_method(:hbx_id).to :organization }
  it { should delegate_method(:legal_name).to :organization }
  it { should delegate_method(:dba).to :organization }
  it { should delegate_method(:fein).to :organization }
  it { should delegate_method(:is_active).to :organization }

  let(:organization) {FactoryGirl.create(:organization)}
  let(:market_kind) {"both"}
  let(:bad_market_kind) {"commodities"}
  let(:primary_general_agency_role) { FactoryGirl.create(:general_agency_role) }
  let(:market_kind_error_message) {"#{bad_market_kind} is not a valid market kind"}

  describe ".new" do
    let(:valid_params) do
      {
        organization: organization,
        market_kind: market_kind,
        entity_kind: "s_corporation",
        primary_general_agency_role: primary_general_agency_role
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(GeneralAgencyProfile.new(**params).save).to be_falsey
      end
    end

    context "with no organization" do
      let(:params) {valid_params.except(:organization)}

      it "should raise" do
        expect{GeneralAgencyProfile.new(**params).save}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no market_kind" do
      let(:params) {valid_params.except(:market_kind)}

      it "should fail validation" do
        expect(GeneralAgencyProfile.create(**params).errors[:market_kind].any?).to be_truthy
      end
    end

    context "with invalid market_kind" do
      let(:params) {valid_params.deep_merge({market_kind: bad_market_kind})}

      it "should fail validation" do
        expect(GeneralAgencyProfile.create(**params).errors[:market_kind]).to eq [market_kind_error_message]
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}
      let(:general_agency_profile) {GeneralAgencyProfile.new(**params)}

      it "should save" do
        expect(general_agency_profile.save!).to be_truthy
      end

      context "and it is saved" do
        before do
          general_agency_profile.save
        end

        it "should be findable by id" do
          expect(GeneralAgencyProfile.find(general_agency_profile.id).id.to_s).to eq general_agency_profile.id.to_s
        end

        context "and it has some employer profile clients" do
          let(:my_client_count)       { 3 }
          let(:general_agency_account) { GeneralAgencyAccount.new(general_agency_profile_id: general_agency_profile.id,
                                          start_on: TimeKeeper.date_of_record)}
          let!(:my_clients)           { FactoryGirl.create_list(:employer_profile, my_client_count,
                                          general_agency_accounts: [general_agency_account] )}

          it "should find all my active employer clients" do
            expect(general_agency_profile.employer_clients.to_a.size).to eq my_client_count
          end

          it "should return employer profile objects" do
            expect(general_agency_profile.employer_clients.first).to be_a EmployerProfile
          end
        end
      end
    end
  end
end
