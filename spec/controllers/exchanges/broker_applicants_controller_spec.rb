require 'rails_helper'

RSpec.describe Exchanges::BrokerApplicantsController do

  describe ".index" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true) }

    before :each do
      sign_in(user)
      get :index, format: :js, xhr:true
    end

    it "should render index" do
      expect(assigns(:broker_applicants))
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/broker_applicants/index")
    end

    context 'when hbx staff role missing' do
      let(:user) { instance_double("User", :has_hbx_staff_role? => false) }

      it 'should redirect when hbx staff role missing' do
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/exchanges/hbx_profiles')
      end
    end
  end

  describe ".edit" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true, :person => person) }
    let(:person) { instance_double("Person", :agent? => false) }
    let(:broker_role) {FactoryBot.create(:broker_role)}

    before :each do
      sign_in(user)
      get :edit, params:{id: broker_role.person.id}, format: :html, xhr:true
    end

    it "should render edit" do
      expect(assigns(:broker_applicant))
      expect(response).to have_http_status(:success)
      expect(response).to render_template("shared/brokers/applicant.html.erb", "layouts/single_column")
    end
  end

  describe ".update" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true, :person => person) }
    let(:person) { instance_double("Person", :agent? => false) }
    let(:broker_role) {FactoryBot.create(:broker_role)}

    before :all do
      @broker_agency_profile = FactoryBot.create(:broker_agency).broker_agency_profile
    end

    before :each do
      @broker_agency_profile.update_attributes({ primary_broker_role: broker_role })
      sign_in(user)
    end

    context 'carrier appointments, license, and reason' do
      it "should update for blank values" do
        put(
          :update,
          params: {
            "update" => "Update",
            id: broker_role.person.id,
            "person" => {
              "broker_role_attributes" => {
                "license" => "0",
                "training" => "0",
                "carrier_appointments" => {}
              }
            }
          }
        )
        broker_role.reload
        expect(broker_role.carrier_appointments).to eq({})
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/exchanges/hbx_profiles')
      end

      it 'should update for set values' do
        broker_role.update_attributes!(carrier_appointments: {})
        broker_role.reload
        expect(broker_role.carrier_appointments).to eq({})
        put(
          :update,
          params: {
            "update" => "Update",
            id: broker_role.person.id,
            "person" => {
              "broker_role_attributes" => {
                "license" => "1",
                "training" => "1",
                "carrier_appointments" => {"Aetna Health Inc" => "true", "United Health Care Insurance" => "true"}
              }
            }
          }
        )
        broker_role.reload
        expect(broker_role.carrier_appointments).to eq({"Aetna Health Inc" => "true", "United Health Care Insurance" => "true"})
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/exchanges/hbx_profiles')
      end
    end

    context 'when application denied' do
      before :each do
        put :update, params:{id: broker_role.person.id, deny: true}, format: :js
        broker_role.reload
      end

      it "should change applicant status to denied" do
        expect(assigns(:broker_applicant))
        expect(broker_role.aasm_state).to eq 'denied'
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/exchanges/hbx_profiles')
      end
    end

    context 'when application extended' do
      context "for denied application" do
        before :each do
          broker_role.deny!
          put :update, params: { id: broker_role.person.id, extend: true }, format: :js
          broker_role.reload
        end

        it 'should move application to application_extended' do
          expect(assigns(:broker_applicant))
          expect(broker_role.aasm_state).to eq 'application_extended'
        end

        it 'should redirect' do
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to('/exchanges/hbx_profiles')
        end
      end

      context "for pending application" do
        before :each do
          allow(broker_role).to receive(:is_primary_broker?).and_return(true)
          broker_role.pending!
          put :update, params: { id: broker_role.person.id, extend: true }, format: :js
          broker_role.reload
        end

        it 'should move application to application_extended' do
          expect(assigns(:broker_applicant))
          expect(broker_role.aasm_state).to eq 'application_extended'
        end

        it 'should redirect' do
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to('/exchanges/hbx_profiles')
        end
      end

      context "for extended application" do
        before :each do
          broker_role.deny!
          broker_role.extend_application!
          put :update, params: { id: broker_role.person.id, extend: true }, format: :js
          broker_role.reload
        end

        it 'should move application to application_extended' do
          expect(assigns(:broker_applicant))
          expect(broker_role.aasm_state).to eq 'application_extended'
        end

        it 'should redirect' do
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to('/exchanges/hbx_profiles')
        end
      end
    end

    context 'when application approved and applicant is not primary broker' do

      before :each do
        FactoryBot.create(:hbx_profile)
        put :update, params:{id: broker_role.person.id, approve: true, person: { broker_role_attributes: { training: true , carrier_appointments: {}} } }, format: :js
        broker_role.reload
      end

      it "should approve and change status to broker agency pending" do
        allow(broker_role).to receive(:broker_agency_profile).and_return(@broker_agency_profile)

        expect(assigns(:broker_applicant))
        expect(broker_role.aasm_state).to eq 'broker_agency_pending'
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/exchanges/hbx_profiles')
      end
    end

    context 'when applicant is a primary broker' do
      let(:broker_agency_profile) { FactoryBot.create(:broker_agency_profile, primary_broker_role_id: broker_role.id) }

      context 'when application is approved' do
        before :each do
          broker_role.update_attributes({ broker_agency_profile_id: @broker_agency_profile.id })
          put :update, params: {id: broker_role.person.id, approve: true, person: { broker_role_attributes: { training: true , carrier_appointments: {}} }} , format: :js
          broker_role.reload
        end

        it "should change applicant status to active" do
          expect(assigns(:broker_applicant))
          expect(broker_role.aasm_state).to eq 'active'
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to('/exchanges/hbx_profiles')
        end

        it "should have training as true in broker role attributes" do
          expect(broker_role.training).to eq true
        end
      end

      context 'when application is updated' do
        before :each do
          broker_role.update_attributes({ broker_agency_profile_id: @broker_agency_profile.id })
          broker_role.approve!
          put :update, params:{id: broker_role.person.id, update: true, person: { broker_role_attributes: { training: true , carrier_appointments: {"Aetna Health Inc"=>"true", "United Health Care Insurance"=>"true"}} }} , format: :js
          broker_role.reload
        end

        it "should change applicant status to active" do
          expect(assigns(:broker_applicant))
          expect(broker_role.aasm_state).to eq 'active'
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to('/exchanges/hbx_profiles')
          #only really testing that the params go through.
          if aca_state_abbreviation == "DC"
            expect(broker_role.carrier_appointments).to eq({"Aetna Health Inc" => "true", "United Health Care Insurance" => "true"})
          else
            expect(broker_role.carrier_appointments).to eq({"Aetna Health Inc"=>"true", "Altus" => nil, "Blue Cross Blue Shield MA" => nil, "Boston Medical Center Health Plan" => nil, "Delta" => nil, "FCHP" => nil, "Guardian" => nil, "Harvard Pilgrim Health Care" => nil, "Health New England" => nil, "Minuteman Health" => nil, "Neighborhood Health Plan" => nil, "Tufts Health Plan Direct" => nil, "Tufts Health Plan Premier" => nil, "United Health Care Insurance" => "true"})
          end
        end

        it "should have training as true in broker role attributes" do
          expect(broker_role.training).to eq true
        end
      end

      context 'when broker carrier appointments enabled and application is pending' do
        context 'when application is pending' do
          let(:carrier_appointments_hash) do
            ca = {}
            "BrokerRole::#{Settings.site.key.upcase}_BROKER_CARRIER_APPOINTMENTS".constantize.stringify_keys.each do |k, _v|
              ca[k] = "true"
            end
            ca
          end

          before :each do
            allow(Settings.aca).to receive(:broker_carrier_appointments_enabled).and_return(true)
            broker_role.update_attributes({ broker_agency_profile_id: @broker_agency_profile.id })
            put :update, params:{id: broker_role.person.id, pending: true, person:  { broker_role_attributes: { training: true , carrier_appointments: {}} }} , format: :js
            broker_role.reload
          end

          it "all broker carrier appointments should be true" do
            expect(broker_role.carrier_appointments).to eq(carrier_appointments_hash)
          end

          it "should change applicant status to broker_agency_pending" do
            expect(assigns(:broker_applicant))
            expect(broker_role.aasm_state).to eq 'broker_agency_pending'
            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to('/exchanges/hbx_profiles')
          end

          it "should have training as true in broker role attributes" do
            expect(broker_role.training).to eq true
          end
        end
      end

      context 'when broker carrier appointments disabled and application is pending' do
        context 'when application is pending' do

          let(:dc_hash) do
            {
              "Aetna Health Inc" => "true",
              "Aetna Life Insurance Company" => "true",
              "Carefirst Bluechoice Inc" => "true"
            }
          end
          let(:ma_hash) do
            {
              "Boston Medical Center Health Plan" => "true",
              "Delta" => "true",
              "FCHP" => "true"
            }
          end
          let(:carrier_appointments_hash) do
            ca = "BrokerRole::#{Settings.site.key.upcase}_BROKER_CARRIER_APPOINTMENTS".constantize.stringify_keys
            merged_hash =
              if Settings.site.key == :dc
                ca.merge!(dc_hash)
              elsif Settings.site.key == :cca
                ca.merge!(dc_hash)
              end
            merged_hash
          end
          before :each do
            person_hash = ActionController::Parameters.new({ broker_role_attributes: { training: true, carrier_appointments: carrier_appointments_hash } }).permit!
            Settings.aca.broker_carrier_appointments_enabled = false
            broker_role.update_attributes({ broker_agency_profile_id: @broker_agency_profile.id })
            put :update, params:{id: broker_role.person.id, pending: true, person: person_hash}, format: :js
            broker_role.reload
          end

          it "broker carrier appointments should be user selected" do
            expect(broker_role.carrier_appointments.find {|_k, v| v == "true" }).to eq(carrier_appointments_hash.find {|_k, v| v == "true" })
          end

          it "should change applicant status to broker_agency_pending" do
            expect(assigns(:broker_applicant))
            expect(broker_role.aasm_state).to eq 'broker_agency_pending'
            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to('/exchanges/hbx_profiles')
          end

          it "should have training as true in broker role attributes" do
            expect(broker_role.training).to eq true
          end
        end
      end

      context 'when application is decertified' do
        before :each do
          broker_role.update_attributes({ broker_agency_profile_id: @broker_agency_profile.id })
          broker_role.approve!
          put :update, params:{id: broker_role.person.id, decertify: true}, format: :js
          broker_role.reload
        end

        it "should change applicant status to decertified" do
          expect(assigns(:broker_applicant))
          expect(broker_role.aasm_state).to eq 'decertified'
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to('/exchanges/hbx_profiles')
        end
      end

      context 'when application is re-certified' do
        before :each do
          broker_role.update_attributes({ broker_agency_profile_id: @broker_agency_profile.id })
          broker_role.approve!
          broker_role.decertify!
          put :update, params:{id: broker_role.person.id, recertify: true}, format: :js
          broker_role.reload
        end

        it "should change applicant status to active" do
          expect(assigns(:broker_applicant))
          expect(broker_role.aasm_state).to eq 'active'
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to('/exchanges/hbx_profiles')
        end
      end
    end
  end
end
