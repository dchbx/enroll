require 'rails_helper'

RSpec.describe PeopleController do
  let(:census_employee_id) { "abcdefg" }
  let(:user) { FactoryGirl.build(:user) }
  let(:email) {FactoryGirl.build(:email)}

  let(:consumer_role){FactoryGirl.build(:consumer_role)}

  let(:census_employee){FactoryGirl.build(:census_employee)}
  let(:employee_role){FactoryGirl.build(:employee_role, :census_employee => census_employee)}
  let(:person) { FactoryGirl.create(:person, :with_employee_role) }


  let(:vlp_document){FactoryGirl.build(:vlp_document)}

  it "GET new" do
    sign_in(user)
    get :new
    expect(response).to have_http_status(:success)
  end

  describe "POST update" do
    let(:vlp_documents_attributes) { {"1" => vlp_document.attributes.to_hash}}
    let(:consumer_role_attributes) { consumer_role.attributes.to_hash}
    let(:person_attributes) { person.attributes.to_hash}
    let(:employee_roles) { person.employee_roles }
    let(:census_employee_id) {employee_roles[0].census_employee_id}

    let(:email_attributes) { {"0"=>{"kind"=>"home", "address"=>"test@example.com"}}}
    let(:addresses_attributes) { {"0"=>{"kind"=>"home", "address_1"=>"address1", "address_2"=>"", "city"=>"city1", "state"=>"DC", "zip"=>"22211"},
        "1"=>{"kind"=>"home", "address_1"=>"address1", "address_2"=>"", "city"=>"city1", "state"=>"DC", "zip"=>"22211"},
        "2"=>{"kind"=>"home", "address_1"=>"address1", "address_2"=>"", "city"=>"city1", "state"=>"DC", "zip"=>"22211"}} }

    before :each do
      allow(Person).to receive(:find).and_return(person)
      allow(Person).to receive(:where).and_return(Person)
      allow(Person).to receive(:first).and_return(person)
      allow(controller).to receive(:sanitize_person_params).and_return(true)
      allow(person).to receive(:consumer_role).and_return(consumer_role)
      allow(consumer_role).to receive(:check_for_critical_changes)
      allow(person).to receive(:update_attributes).and_return(true)
      allow(person).to receive(:is_consumer_role_active?).and_return(false)
      person_attributes[:addresses_attributes] = addresses_attributes
      sign_in user
      post :update, id: person.id, person: person_attributes
    end

    context "duplicate addresses records" do
      it "clean all existing addresses " do
        expect(person.addresses).to eq []
      end
    end

    context "when individual" do

      before do
        allow(request).to receive(:referer).and_return("insured/families/personal")
        allow(person).to receive(:is_consumer_role_active?).and_return(true)
      end
      it "update person" do
        allow(consumer_role).to receive(:find_document).and_return(vlp_document)
        allow(vlp_document).to receive(:save).and_return(true)
        consumer_role_attributes[:vlp_documents_attributes] = vlp_documents_attributes
        person_attributes[:consumer_role_attributes] = consumer_role_attributes

        post :update, id: person.id, person: person_attributes
        expect(response).to redirect_to(personal_insured_families_path)
        expect(assigns(:person)).not_to be_nil
        expect(flash[:notice]).to eq 'Person was successfully updated.'
      end

      it "should update is_applying_coverage" do
        allow(person).to receive(:update_attributes).and_return(true)
        person_attributes.merge!({"is_applying_coverage" => "false"})

        post :update, id: person.id, person: person_attributes
        expect(assigns(:person).consumer_role.is_applying_coverage).to eq false
      end
    end

    context "when employee" do
      it "when employee" do
        person_attributes[:emails_attributes] = email_attributes
        allow(controller).to receive(:get_census_employee).and_return(census_employee)
        allow(person).to receive(:update_attributes).and_return(true)

        post :update, id: person.id, person: person_attributes
        expect(response).to redirect_to(family_account_path)
        expect(flash[:notice]).to eq 'Person was successfully updated.'
      end
    end
  end
end
