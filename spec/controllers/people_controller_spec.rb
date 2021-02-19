# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PeopleController, dbclean: :after_each do
  let(:census_employee_id) { "abcdefg" }
  let(:user) { FactoryBot.build(:user) }
  let(:email) {FactoryBot.build(:email)}
  let(:consumer_role){FactoryBot.build(:consumer_role, :contact_method => "Paper Only")}
  let(:census_employee){FactoryBot.build(:census_employee)}
  let(:employee_role){FactoryBot.build(:employee_role, :census_employee => census_employee)}
  let(:person) { FactoryBot.create(:person) }


  let(:vlp_document){FactoryBot.build(:vlp_document)}

  it "GET new" do
    sign_in(user)
    get :new
    expect(response).to have_http_status(:success)
  end

  describe "POST create" do
    context "with valid attributes" do
      it 'should add a new person' do
        expect { post :create, params: {person: FactoryBot.attributes_for(:person)} }.to change(Person,:count).by(0)
      end
    end

    context "with invalid attributes"  do
      it 'should not add a new person' do
        expect { post :create, params: {person: FactoryBot.attributes_for(:person,:with_bad_mailing_address)} }.to_not change(Person,:count)
      end
    end
  end

  describe "POST update" do
    let(:vlp_documents_attributes) { {"1" => vlp_document.attributes.to_hash}}
    let(:consumer_role_attributes) { consumer_role.attributes.to_hash}
    let(:person_attributes) { person.attributes.to_hash}
    let(:email_attributes) { {"0"=>{"kind"=>"home", "address"=>"test@example.com"}}}
    let(:addresses_attributes) { {"0"=>{"kind"=>"home", "address_1"=>"address1_a", "address_2"=>"", "city"=>"city1", "state"=>"DC", "zip"=>"22211", "id"=> person.addresses[0].id.to_s},
        "1"=>{"kind"=>"mailing", "address_1"=>"address1_b", "address_2"=>"", "city"=>"city1", "state"=>"DC", "zip"=>"22211", "id"=> person.addresses[1].id.to_s} } }

    before :each do
      allow(Person).to receive(:find).and_return(person)
      allow(Person).to receive(:where).and_return(Person)
      allow(Person).to receive(:first).and_return(person)
      allow(controller).to receive(:sanitize_person_params).and_return(true)
      allow(person).to receive(:consumer_role).and_return(consumer_role)
      allow(person).to receive(:employee_roles).and_return [employee_role]
      allow_any_instance_of(VlpDoc).to receive(:sensitive_info_changed?).and_return([false, false])
      allow(person).to receive(:update_attributes).and_return(true)
      allow(person).to receive(:is_consumer_role_active?).and_return(false)
      person_attributes[:addresses_attributes] = addresses_attributes
      person_attributes[:consumer_role_attributes] = consumer_role_attributes

      sign_in user
      post :update, params: {id: person.id, person: person_attributes}
    end


    context "to verify if addresses are updated?" do

      it "should not create new address instances on update" do
        expect(assigns(:valid_vlp)).to be_nil
        expect(person.addresses.count).to eq 2
      end

      it "should not empty the person's addresses on update" do
        expect(assigns(:valid_vlp)).to be_nil
        expect(person.addresses).not_to eq []
      end
    end

    context "employee roles are updated" do
      it "should update active employee role's contact method to match consumer role contact method" do
        expect(person.consumer_role.contact_method).to eq(person.employee_roles.first.contact_method)
      end
    end

    context "when individual" do
      before do
        request.env['HTTP_REFERER'] = "insured/families/personal"
        allow(person).to receive(:is_consumer_role_active?).and_return(true)
      end
      it "update person" do
        allow(consumer_role).to receive(:find_document).and_return(vlp_document)
        allow(consumer_role).to receive(:check_for_critical_changes).and_return(true)
        allow(vlp_document).to receive(:save).and_return(true)
        allow(consumer_role).to receive(:check_native_status).and_return(true)
        consumer_role_attributes[:vlp_documents_attributes] = vlp_documents_attributes
        person_attributes[:consumer_role_attributes] = consumer_role_attributes
        post :update,  params: {id: person.id, person: person_attributes}
        expect(response).to redirect_to(personal_insured_families_path)
        expect(assigns(:person)).not_to be_nil
        expect(assigns(:valid_vlp)).to eq(true)
        expect(flash[:notice]).to eq 'Person was successfully updated.'
      end

      it "should update is_applying_coverage" do
        allow(person).to receive(:update_attributes).and_return(true)
        allow(consumer_role).to receive(:check_for_critical_changes).and_return(true)
        allow(consumer_role).to receive(:check_native_status).and_return(true)
        person_attributes.merge!({"is_applying_coverage" => "false"})

        post :update, params: {id: person.id, person: person_attributes}
        expect(assigns(:valid_vlp)).to eq(true)
        expect(assigns(:person).consumer_role.is_applying_coverage).to eq false
      end

      context 'person update failed' do
        let!(:invalid_vlp_doc) { FactoryBot.build(:vlp_document, subject: 'Other (With Alien Number)') }
        let!(:consumer_role_attributes) { person.consumer_role.attributes.to_hash}
        let!(:person_attributes) { person.attributes.to_hash}
        let!(:invalid_vlp_documents_attributes) { {"1" => invalid_vlp_doc.attributes.to_hash}}

        before do
          allow(person).to receive(:is_consumer_role_active?).and_return(true)
          allow(consumer_role).to receive(:check_for_critical_changes).and_return(true)
          consumer_role_attributes[:vlp_documents_attributes] = invalid_vlp_documents_attributes
          person_attributes[:consumer_role] = consumer_role_attributes
          post :update, params: {id: person.id, person: person_attributes}
        end

        it "should update is_applying_coverage" do
          expect(assigns(:valid_vlp)).to eq(false)
          expect(flash[:alert]).to include('Person update failed.')
        end
      end
    end

    context "when employee" do
      it "when employee" do
        person_attributes[:emails_attributes] = email_attributes
        allow(controller).to receive(:get_census_employee).and_return(census_employee)
        allow(person).to receive(:update_attributes).and_return(true)

        post :update, params: {id: person.id, person: person_attributes}
        expect(response).to redirect_to(family_account_path)
        expect(flash[:notice]).to eq 'Person was successfully updated.'
      end
    end
  end

  describe 'show_roles' do
    let(:user) { FactoryBot.build(:user) }
    let(:person) {FactoryBot.create(:person, user: user)}

    before do
      sign_in(user)
      get :show_roles, params: {id: person.id}
    end

    it 'should return success status' do
      expect(response).to have_http_status(:success)
    end

    it 'should assign instance variable' do
      expect(assigns(:person)).to eq person
    end

    it 'should render manage_account template' do
      expect(response).to render_template("people/show_roles")
    end
  end

  describe 'Manage Account' do
    let(:user) { FactoryBot.build(:user) }
    let(:person) {FactoryBot.create(:person, user: user)}

    before do
      sign_in(user)
      get :manage_account, params: {id: person.id}
    end

    it 'should return success status' do
      expect(response).to have_http_status(:success)
    end

    it 'should assign instance variable' do
      expect(assigns(:person)).to eq person
    end

    it 'should render manage_account template' do
      expect(response).to render_template("people/manage_account")
    end
  end

  describe 'available_accounts' do
    let(:user) { FactoryBot.build(:user) }
    let(:person) {FactoryBot.create(:person, user: user)}

    before do
      sign_in(user)
      get :available_accounts, params: {id: person.id}
    end

    it 'should return success status' do
      expect(response).to have_http_status(:success)
    end

    it 'should assign instance variable' do
      expect(assigns(:person)).to eq person
    end

    it 'should render manage_account template' do
      expect(response).to render_template("people/available_accounts")
    end
  end

  describe 'Personal Info' do
    let(:user) { FactoryBot.build(:user) }
    let(:person) {FactoryBot.create(:person, user: user)}

    before do
      sign_in(user)
      get :personal_info, params: {id: person.id}
    end

    it 'should return success status' do
      expect(response).to have_http_status(:success)
    end

    it 'should assign instance variable' do
      expect(assigns(:person)).to eq person
    end

    it 'should render manage_account template' do
      expect(response).to render_template("people/personal_info")
    end
  end

  describe 'Update Personal Info' do
    let(:user) { FactoryBot.build(:user) }
    let(:invalid_phones_attributes) {{"0" => {"kind" => "home", "_destroy" => "false", "full_phone_number" => "(848) 484-84"}, "1" => {"kind" => "mobile", "_destroy" => "false", "full_phone_number" => ""}}}
    let(:valid_phones_attributes) {{"0" => {"kind" => "home", "_destroy" => "false", "full_phone_number" => "(848) 484-8499"}, "1" => {"kind" => "mobile", "_destroy" => "false", "full_phone_number" => ""}}}
    let(:person_params){{"dob" => "1985-10-01", "first_name" => "Nikola","gender" => "male","last_name" => "Rasevic","middle_name" => "Veljko", "is_incarcerated" => "false"}}
    let(:person) {FactoryBot.create(:person, user: user)}

    before do
      sign_in(user)
    end

    it 'should not update existing person with invalid phone number' do
      person_params[:phones_attributes] = invalid_phones_attributes
      put :update_personal_info, params: {person: person_params, id: person.id}
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to match('Person update failed. Phones is invalid')
    end

    it 'should update existing person with valid phone numbe' do
      person_params[:phones_attributes] = valid_phones_attributes
      put :update_personal_info, params: {person: person_params, id: person.id}
      expect(response).to have_http_status(:redirect)
      expect(flash[:notice]).to match('Person successfully updated.')
    end
  end
end
