require 'rails_helper'

RSpec.describe BrokerAgencies::BrokerRolesController do

  describe ".new_broker" do

    context 'with non AJAX request' do
      before :each do
        get :new_broker
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render the new template" do
        expect(response).to render_template("new")
      end

      it "should assign variables" do
        expect(assigns(:broker_candidate)).to be_kind_of(Forms::BrokerCandidate)
        expect(assigns(:filter)).to eq('broker')
        expect(assigns(:agency_type)).to eq('new')
      end
    end

    context 'with AJAX request' do
      before :each do
        xhr :get, :new_broker, filter: 'broker', format: :js
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render the new template" do
        expect(response).to render_template("new_broker")
      end

      it "should assign variables" do
        expect(assigns(:broker_candidate)).to be_kind_of(Forms::BrokerCandidate)
        expect(assigns(:filter)).to eq('broker')
      end
    end
  end

  describe ".new_staff_member" do
    before :each do
      xhr :get, :new_staff_member, filter: 'staff', format: :js
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the new template" do
      expect(response).to render_template("new_staff_member")
    end

    it "should assign variables" do
      expect(assigns(:broker_candidate)).to be_kind_of(Forms::BrokerCandidate)
      expect(assigns(:filter)).to eq('staff')
    end
  end

  describe ".new_broker_agency" do
    before :each do
      xhr :get, :new_broker_agency, filter: 'broker', agency_type: 'new', format: :js
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render the new template" do
      expect(response).to render_template("new_broker_agency")
    end

    it "should assign variables" do
      expect(assigns(:organization)).to be_kind_of(Forms::BrokerAgencyProfile)
      expect(assigns(:filter)).to eq('broker')
      expect(assigns(:agency_type)).to eq('new')
    end
  end

  describe ".create" do
    context "with new broker agency" do

      let(:organization) { instance_double("Organization") }

      let(:organization_params) { {
        first_name: 'firstname',
        last_name: 'lastname',
        dob: "2015-06-01",
        email: 'useraccount@gmail.com',
        npn: "8422323232",
        legal_name: 'useragency',
        fein: "223232323",
        entity_kind: "c_corporation",
        market_kind: "shop",
        working_hours: "0",
        accept_new_clients: "0",
        office_locations_attributes: office_locations
      } }

      let(:office_locations) { {
        "0" => {
          address_attributes: address_attributes,
          phone_attributes: phone_attributes
        }
      }}

      let(:address_attributes) {
        {
          kind: "primary",
          address_1: "99 N ST",
          city: "washignton",
          state: "dc",
          zip: "20006"
        }
      }

      let(:phone_attributes) {
        {
          kind: "phone main",
          area_code: "202",
          number: "324-2232"
        }
      }

      context "when valid" do
        before :each do
          # allow(controller).to receive(:verify_recaptcha).and_return(true)
          allow(::Forms::BrokerAgencyProfile).to receive(:new).and_return(organization)
          allow(organization).to receive(:save).and_return(true)
          post :create, :organization => organization_params
        end

        it "should be a redirect" do
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(broker_registration_path)
        end

        it "should has successful notice" do
          expect(flash[:notice]).to eq "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
        end
      end

      context "when invalid" do
        before :each do
          allow(::Forms::BrokerAgencyProfile).to receive(:new).and_return(organization)
          allow(organization).to receive(:save).and_return(false)
          post :create, :organization => organization_params
        end

        it "should be a redirect" do
          expect(response).to render_template('new')
        end

        it "should assign variables" do
          expect(assigns(:agency_type)).to eq "new"
        end
      end

      # context "when recaptcha fails" do
      #   before :each do
      #     allow(controller).to receive(:verify_recaptcha).and_return(false)
      #     allow(::Forms::BrokerAgencyProfile).to receive(:new).and_return(organization)
      #     allow(organization).to receive(:save).and_return(true)
      #     post :create, :organization => organization_params
      #   end
      #
      #   it "should be a redirect" do
      #     expect(response).to render_template('new')
      #   end
      #
      #   it "should assign variables" do
      #     expect(assigns(:agency_type)).to eq "new"
      #   end
      # end
    end

    context "with broker for existing agency" do

      let(:person) { instance_double("Person") }

      let(:person_params) { {
        broker_applicant_type: "broker",
        first_name: "firstname",
        last_name: "lastname",
        dob: "1993-06-03",
        email: "useraccount@gmail.com",
        npn: "8323232323",
        broker_agency_id: "55929d867261670838550000"
      } }

      context "when valid" do
        before :each do
          # allow(controller).to receive(:verify_recaptcha).and_return(true)
          allow(::Forms::BrokerCandidate).to receive(:new).and_return(person)
          allow(person).to receive(:save).and_return(true)
          post :create, :person => person_params
        end

        it "should be a redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should has successful notice" do
          expect(flash[:notice]).to eq "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
        end
      end

      context "when invalid" do
        before :each do
          allow(::Forms::BrokerCandidate).to receive(:new).and_return(person)
          allow(person).to receive(:save).and_return(false)
          post :create, :person => person_params
        end

        it "should be a redirect" do
          expect(response).to render_template('new')
        end

        it "should assign variables" do
          expect(assigns(:filter)).to eq "broker"
        end
      end

      # context "when recaptcha fails" do
      #   before :each do
      #     # allow(controller).to receive(:verify_recaptcha).and_return(false)
      #     allow(::Forms::BrokerCandidate).to receive(:new).and_return(person)
      #     allow(person).to receive(:save).and_return(true)
      #     post :create, :person => person_params
      #   end
      #
      #   it "should be a redirect" do
      #     expect(response).to render_template('new')
      #   end
      #
      #   it "should assign variables" do
      #     expect(assigns(:filter)).to eq "broker"
      #   end
      # end
    end

    context "with staff member for existing agency" do

      let(:person) { instance_double("Person") }

      let(:person_params) { {
        broker_applicant_type: "staff",
        first_name: "firstname",
        last_name: "lastname",
        dob: "1993-06-03",
        email: "useraccount@gmail.com",
        broker_agency_id: "55929d867261670838550000"
      } }

      context "when valid" do
        before :each do
          allow(::Forms::BrokerCandidate).to receive(:new).and_return(person)
          allow(person).to receive(:save).and_return(true)
          post :create, :person => person_params
        end

        it "should be a redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should has successful notice" do
          expect(flash[:notice]).to eq "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
        end
      end

      context "when invalid" do
        before :each do
          allow(::Forms::BrokerCandidate).to receive(:new).and_return(person)
          allow(person).to receive(:save).and_return(false)
          post :create, :person => person_params
        end

        it "should be a redirect" do
          expect(response).to render_template('new')
        end

        it "should assign variables" do
          expect(assigns(:filter)).to eq "staff"
        end
      end
    end
  end

  context "search_broker_agency", :dbclean => :after_each do
    before :each do
      @organization = FactoryGirl.create(:broker_agency)
      @broker_agency_profile = @organization.broker_agency_profile
    end

    context "with full" do
      context "search by legal_name" do
        before do
          xhr :get, :search_broker_agency, broker_agency_search: @organization.legal_name, format: :js
        end

        it "should be a success" do
          expect(response).to have_http_status(:success)
          expect(response).to render_template("search_broker_agency")
          expect(assigns(:broker_agency_profiles)).to eq [@broker_agency_profile]
        end
      end

      context "search by fein" do
        before do
          xhr :get, :search_broker_agency, broker_agency_search: @broker_agency_profile.fein, format: :js
        end

        it "should be a success" do
          expect(response).to have_http_status(:success)
          expect(response).to render_template("search_broker_agency")
          expect(assigns(:broker_agency_profiles)).to eq [@broker_agency_profile]
        end
      end
    end

    context "with partial" do
      context "search by legal_name" do
        before do
          xhr :get, :search_broker_agency, broker_agency_search: @organization.legal_name.last(5), format: :js
        end

        it "should be a success" do
          expect(response).to have_http_status(:success)
          expect(response).to render_template("search_broker_agency")
          expect(assigns(:broker_agency_profiles)).to eq [@broker_agency_profile]
        end
      end

      context "search by fein" do
        before do
          xhr :get, :search_broker_agency, broker_agency_search: @broker_agency_profile.fein.last(5), format: :js
        end

        it "should be a success" do
          expect(response).to have_http_status(:success)
          expect(response).to render_template("search_broker_agency")
          expect(assigns(:broker_agency_profiles)).to eq [@broker_agency_profile]
        end
      end
    end
  end
end
