require 'rails_helper'

module BenefitSponsors
  RSpec.describe Profiles::Employers::BrokerAgencyController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }
    let!(:security_question)  { FactoryGirl.create_default :security_question }
    let!(:rating_area)   { FactoryGirl.create :benefit_markets_locations_rating_area }
    let!(:service_area)  { FactoryGirl.create :benefit_markets_locations_service_area }


    let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:organization_with_hbx_profile)  { site.owner_organization }
    let(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)    { organization.employer_profile }
    let(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

    let!(:broker_agency_organization1) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, legal_name: 'First Legal Name', site: site) }
    let!(:broker_agency_profile1) { broker_agency_organization1.broker_agency_profile }
    let!(:person1) { FactoryGirl.create(:person) }
    let!(:broker_role1) { FactoryGirl.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile1.id, person: person1) }

    let!(:broker_agency_organization2) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, legal_name: 'Second Legal Name', site: site) }
    let!(:broker_agency_profile2) { broker_agency_organization2.broker_agency_profile }
    let!(:person2) { FactoryGirl.create(:person) }
    let!(:broker_role2) { FactoryGirl.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile2.id, person: person2) }

    let!(:user_with_hbx_staff_role) { FactoryGirl.create(:user, :with_hbx_staff_role) }
    let!(:person) { FactoryGirl.create(:person, user: user_with_hbx_staff_role )}
    let(:broker_managenement_form_class) { BenefitSponsors::Organizations::OrganizationForms::BrokerManagementForm }

    after :each do
      DatabaseCleaner.clean
    end

    before :each do
      user_with_hbx_staff_role.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id)
      user_with_hbx_staff_role.person.hbx_staff_role.save!

      benefit_sponsorship.save!
      broker_agency_profile1.update_attributes!(primary_broker_role_id: broker_role1.id)
      broker_agency_profile1.approve!
      broker_agency_profile2.update_attributes!(primary_broker_role_id: broker_role2.id)
      broker_agency_profile2.approve!
      organization.reload
    end

    after :all do
      DatabaseCleaner.clean
    end

    describe 'for index' do
      context 'with out filter criteria' do
        before(:each) do
          sign_in(user_with_hbx_staff_role)
          xhr :get, :index, employer_profile_id: employer_profile.id, format: :js
        end

        it 'should be a success' do
          expect(response).to have_http_status(:success)
        end

        it 'should render the new template' do
          expect(response).to render_template('index')
        end

        it 'should assign orgs variable' do
          expect(assigns(:orgs)).to include(broker_agency_profile1.organization)
          expect(assigns(:orgs)).to include(broker_agency_profile2.organization)
        end

        it 'should assign broker_agency_profiles variable' do
          expect(assigns(:broker_agency_profiles)).to include(broker_agency_profile1)
          expect(assigns(:broker_agency_profiles)).to include(broker_agency_profile2)
        end

        it 'should assign page_alphabets variable' do
          expect(assigns(:page_alphabets)).to eq [broker_agency_profile1.legal_name[0], broker_agency_profile2.legal_name[0]]
        end

        it 'should assign employer_profile variable' do
          expect(assigns(:employer_profile)).to eq employer_profile
        end
      end

      context 'with filter criteria' do
        before(:each) do
          sign_in(user_with_hbx_staff_role)
          xhr :get, :index, employer_profile_id: employer_profile.id, q: broker_agency_profile1.legal_name[0], format: :js
        end

        it 'should be a success' do
          expect(response).to have_http_status(:success)
        end

        it 'should render the new template' do
          expect(response).to render_template('index')
        end

        it 'should assign broker_agency_profiles variable' do
          expect(assigns(:broker_agency_profiles)).to include(broker_agency_profile1)
        end

        it 'should assign page_alphabets variable' do
          expect(assigns(:filter_criteria)).to eq ({"q"=>broker_agency_profile1.legal_name[0]})
        end

        it 'should assign employer_profile variable' do
          expect(assigns(:employer_profile)).to eq employer_profile
        end
      end

      context 'with filter criteria' do
        before(:each) do
          sign_in(user_with_hbx_staff_role)
          xhr :get, :index, employer_profile_id: employer_profile.id, q: broker_agency_profile2.legal_name[0], format: :js
        end

        it 'should assign broker_agency_profiles variable' do
          expect(assigns(:broker_agency_profiles)).to include(broker_agency_profile2)
        end

      end

      context 'with out filter criteria with page label' do
        before :each do
          sign_in(user_with_hbx_staff_role)
          xhr :get, :index, employer_profile_id: employer_profile.id, page: broker_agency_profile1.legal_name[0], format: :js
        end

        it 'should be a success' do
          expect(response).to have_http_status(:success)
        end

        it 'should render the new template' do
          expect(response).to render_template('index')
        end

        it 'should assign orgs variable' do
          expect(assigns(:orgs)).to include(broker_agency_profile1.organization)
          expect(assigns(:orgs)).to include(broker_agency_profile2.organization)
        end

        it 'should assign broker_agency_profiles variable with the filter' do
          expect(assigns(:broker_agency_profiles)).to eq [broker_agency_profile1]
        end

        it 'should assign organizations variable with the filter' do
          expect(assigns(:organizations)).to eq [broker_agency_profile1.organization]
        end

        it 'should assign page_alphabet variable' do
          expect(assigns(:page_alphabet)).to eq broker_agency_profile1.legal_name[0]
        end

        it 'should assign page_alphabets variable' do
          expect(assigns(:page_alphabets)).to eq [broker_agency_profile1.legal_name[0], broker_agency_profile2.legal_name[0]]
        end

        it 'should assign employer_profile variable' do
          expect(assigns(:employer_profile)).to eq employer_profile
        end
      end

      context 'with out filter criteria and pagination' do
        before :each do
          sign_in(user_with_hbx_staff_role)
          xhr :get, :index, employer_profile_id: employer_profile.id, page: broker_agency_profile1.legal_name[0], organization_page: 1, format: :js
        end

        it 'should be a success' do
          expect(response).to have_http_status(:success)
        end

        it 'should render the new template' do
          expect(response).to render_template('index')
        end

        it 'should assign orgs variable' do
          expect(assigns(:orgs)).to include(broker_agency_profile1.organization)
          expect(assigns(:orgs)).to include(broker_agency_profile2.organization)
        end

        it 'should assign broker_agency_profiles variable with the filter' do
          expect(assigns(:broker_agency_profiles)).to eq [broker_agency_profile1]
        end

        it 'should assign organizations variable with the filter' do
          expect(assigns(:organizations)).to eq [broker_agency_profile1.organization]
        end

        it 'should assign page_alphabet variable' do
          expect(assigns(:page_alphabet)).to eq broker_agency_profile1.legal_name[0]
        end

        it 'should assign page_alphabets variable' do
          expect(assigns(:page_alphabets)).to eq [broker_agency_profile1.legal_name[0], broker_agency_profile2.legal_name[0]]
        end

        it 'should assign employer_profile variable' do
          expect(assigns(:employer_profile)).to eq employer_profile
        end
      end

      context 'with filter criteria with both page label and pagination' do
        before :each do
          sign_in(user_with_hbx_staff_role)
          xhr :get, :index, employer_profile_id: employer_profile.id, q: broker_agency_profile1.legal_name[0], organization_page: 1, format: :js
        end

        it 'should be a success' do
          expect(response).to have_http_status(:success)
        end

        it 'should render the new template' do
          expect(response).to render_template('index')
        end

        it 'should assign broker_agency_profiles variable with the filter' do
          expect(assigns(:broker_agency_profiles)).to eq [broker_agency_profile1]
        end

        it 'should assign employer_profile variable' do
          expect(assigns(:employer_profile)).to eq employer_profile
        end
      end
    end

    describe 'for create' do
      context 'for assigning a new broker' do

        before(:each) do
          allow_any_instance_of(HbxStaffRole).to receive(:permission).and_return(double(modify_employer: true))
          sign_in(user_with_hbx_staff_role)
          @request.env['HTTP_REFERER'] = "/benefit_sponsors/profiles/employers/employer_profiles/#{employer_profile.id.to_s}?tab=brokers"
          post :create, employer_profile_id: employer_profile.id, broker_role_id: broker_role1.id, broker_agency_id: broker_agency_profile1.id
        end

        it 'should initialize broker management form' do
          expect(assigns(:broker_management_form).class).to eq broker_managenement_form_class
        end

        it 'should redirect to show page' do
          expect(response).to redirect_to(profiles_employers_employer_profile_path(employer_profile, tab: 'brokers'))
        end

        it 'should flash a message with the following text on sucessful broker assignment' do
          expect(flash[:notice]).to eq "Your broker has been notified of your selection and should contact you shortly. You can always call or email them directly. If this is not the broker you want to use, select 'Change Broker'."
        end

        it 'should add a new broker_agency_account to the benefit_sponsorship accociated to the employer profile' do
          expect(assigns(:broker_management_form).broker_agency_profile_id).to eq broker_agency_profile1.id.to_s
        end

        it 'should assign employer_profile variable' do
          expect(assigns(:employer_profile)).to eq employer_profile
        end

        it 'should assign broker_agency_profile variable' do
          expect(assigns(:broker_agency_profile)).to eq broker_agency_profile1
        end
      end
    end

    describe 'for terminate' do
      before :each do
        allow_any_instance_of(HbxStaffRole).to receive(:permission).and_return(double(modify_employer: true))
        employer_profile.hire_broker_agency(broker_agency_profile1)
        sign_in(user_with_hbx_staff_role)
        get :terminate, employer_profile_id: employer_profile.id, direct_terminate: 'true', broker_agency_id: broker_agency_profile1.id, termination_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      context 'for terminating an exisiting broker' do
        it 'should initialize broker management form' do
          expect(assigns(:broker_management_form).class).to eq broker_managenement_form_class
        end

        it 'should redirect to show page' do
          expect(response).to redirect_to(profiles_employers_employer_profile_path(employer_profile, tab: 'brokers'))
        end

        it 'should flash a message with the following text on sucessful broker assignment' do
          expect(flash[:notice]).to eq 'Broker terminated successfully.'
        end

        it 'should terminate the broker_agency' do
          expect(employer_profile.active_benefit_sponsorship.broker_agency_accounts.count).to eq 0
        end

        it 'should assign employer_profile variable' do
          expect(assigns(:employer_profile)).to eq employer_profile
        end

        it 'should assign broker_agency_profile variable' do
          expect(assigns(:broker_agency_profile)).to eq broker_agency_profile1
        end
      end
    end
  end
end
