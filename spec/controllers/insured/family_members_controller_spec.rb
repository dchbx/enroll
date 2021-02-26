# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insured::FamilyMembersController, dbclean: :after_each do
  let(:user) { instance_double("User", :primary_family => test_family, :person => person) }
  let(:qle) { FactoryBot.create(:qualifying_life_event_kind) }
  let(:test_family) { FactoryBot.build(:family, :with_primary_family_member) }
  let(:person) { test_family.primary_family_member.person }
  let(:published_plan_year)  { FactoryBot.build(:plan_year, aasm_state: :published)}
  let(:employer_profile) { FactoryBot.create(:employer_profile) }
  let(:employee_role) { FactoryBot.create(:employee_role, employer_profile: employer_profile, person: person) }
  let(:employee_role_id) { employee_role.id }
  let(:census_employee) { FactoryBot.create(:census_employee) }

  before do
    employer_profile.plan_years << published_plan_year
    employer_profile.save
  end


  describe "GET index" do
    context 'normal' do
      before(:each) do
        allow(person).to receive(:broker_role).and_return(nil)
        allow(user).to receive(:person).and_return(person)
        allow(user).to receive(:has_hbx_staff_role?).and_return(false)
        sign_in(user)
        allow(controller.request).to receive(:referer).and_return('http://dchealthlink.com/insured/interactive_identity_verifications')
        get :index, params: {employee_role_id: employee_role_id}
      end

      it "renders the 'index' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("index")
      end

      it "assigns the person" do
        expect(assigns(:person)).to eq person
      end

      it "assigns the family" do
        expect(assigns(:family)).to eq nil #wat?
      end
    end

    context 'with no referer' do
      before(:each) do
        allow(person).to receive(:broker_role).and_return(nil)
        allow(user).to receive(:person).and_return(person)
        allow(user).to receive(:has_hbx_staff_role?).and_return(false)
        sign_in(user)
        allow(controller.request).to receive(:referer).and_return(nil)
        get :index, params: {employee_role_id: employee_role_id}
      end

      it "renders the 'index' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("index")
      end

      it "assigns the person" do
        expect(assigns(:person)).to eq person
      end

      it "assigns the family" do
        expect(assigns(:family)).to eq nil #wat?
      end
    end

    # Some times Effective dates vary even for the next day. So creating a new SEP & re-calculating effective on dates
    context "with sep_id in params" do

      subject { Observers::NoticeObserver.new }

      let(:sep) { FactoryBot.create :special_enrollment_period, family: test_family }
      let(:dup_sep) { double("SpecialEnrPeriod", qle_on: TimeKeeper.date_of_record - 5.days) }

      before :each do
        allow(person).to receive(:broker_role).and_return(nil)
        allow(user).to receive(:person).and_return(person)
        allow(user).to receive(:has_hbx_staff_role?).and_return(false)
        sign_in(user)
        allow(controller).to receive(:validate_address_params).and_return []
        allow(controller.request).to receive(:referer).and_return(nil)
      end

      it "should not duplicate sep if using current sep on same day" do
        get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
        expect(assigns(:sep)).to eq sep
      end

      context "when using old active sep" do

        before do
          sep.update_attributes(submitted_at: TimeKeeper.datetime_of_record - 1.day)
        end

        it "should not get assign with old sep" do
          get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
          expect(assigns(:sep)).not_to eq sep
        end

        it "should duplicate sep" do
          allow(controller).to receive(:duplicate_sep).and_return dup_sep
          get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
          expect(assigns(:sep)).to eq dup_sep
        end

        it "should have the today's date as submitted_at" do
          get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
          expect(assigns(:sep).submitted_at.to_date).to eq TimeKeeper.date_of_record
        end

        it "qle market kind is should be shop" do
          expect(qle.market_kind).to eq "shop"
        end
      end

      context "when using expired active sep" do

        let(:active_qle) { create(:qualifying_life_event_kind, title: "Married", market_kind: "shop", reason: "marriage", start_on: TimeKeeper.date_of_record.prev_month.beginning_of_month, end_on: TimeKeeper.date_of_record.next_month.end_of_month) }

        before do
          sep.update_attributes(qualifying_life_event_kind_id: active_qle.id, submitted_at: TimeKeeper.datetime_of_record - 1.day, created_at: sep.created_at - 2.day)
          active_qle.update_attributes(is_active: false, end_on: TimeKeeper.date_of_record - 1.day)
        end

        it "should not get assign with old sep" do
          get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
          expect(assigns(:sep)).not_to eq sep
        end

        it "should duplicate sep" do
          allow(controller).to receive(:duplicate_sep).and_return dup_sep
          get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
          expect(assigns(:sep)).to eq dup_sep
        end

        it "should have the today's date as submitted_at" do
          get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
          expect(assigns(:sep).submitted_at.to_date).to eq TimeKeeper.date_of_record
        end

        it "qle market kind is should be shop" do
          expect(qle.market_kind).to eq "shop"
        end
      end
    end

    it "with qle_id" do
      allow(person).to receive(:primary_family).and_return(test_family)
      allow(person).to receive(:broker_role).and_return(nil)
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(employee_role).to receive(:save!).and_return(true)
      allow(employer_profile).to receive(:published_plan_year).and_return(published_plan_year)
      sign_in user
      allow(controller).to receive(:validate_address_params).and_return []
      allow(controller.request).to receive(:referer).and_return('http://dchealthlink.com/insured/interactive_identity_verifications')
      expect do
        get :index, params: {employee_role_id: employee_role_id, qle_id: qle.id, effective_on_kind: 'date_of_event', qle_date: '10/10/2015', published_plan_year: '10/10/2015'}
      end.to change(test_family.special_enrollment_periods, :count).by(1)
    end
  end

  describe "GET show" do
    let(:dependent) { double("Dependent") }
    let(:family_member) {double("FamilyMember", id: double("id"))}

    before(:each) do
      allow(Forms::FamilyMember).to receive(:find).and_return(dependent)
      sign_in(user)
      get :show, params: {id: family_member.id}
    end

    it "should render show templage" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("show")
    end
  end

  describe "GET new" do
    let(:family_id) { "addbedddedtotallyafamiyid" }
    let(:dependent) { double }

    before(:each) do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:new).with({:family_id => family_id}).and_return(dependent)
      get :new, params: {family_id: family_id}
    end

    it "renders the 'new' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new")
    end

    it "assigns the dependent" do
      expect(assigns(:dependent)).to eq dependent
    end
  end

  describe "POST create" do
    let(:address) { double }
    let(:valid_addresses_attributes) do
      {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211"},
       "1" => {"kind" => "mailing", "address_1" => "address1_b", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211" } }
    end
    let(:invalid_addresses_attributes) do
      {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "222"},
       "1" => {"kind" => "mailing", "address_1" => "test", "address_2" => "", "city" => "test", "state" => "DC", "zip" => "223"} }
    end
    let(:dependent_properties) { {addresses: valid_addresses_attributes, :family_id => test_family.id, same_with_primary: "false" } }
    let(:save_result) { false }
    let!(:test_family) { FactoryBot.create(:family, :with_primary_family_member) }

    describe "with an invalid dependent" do
      before :each do
        sign_in(user)
        # No Resident Role
        allow_any_instance_of(Forms::FamilyMember).to receive(:save).and_return(save_result)
        post :create, params: {dependent: dependent_properties}, :format => "js"
      end

      it "should assign the dependent" do
        expect(assigns(:dependent).class).to eq(Forms::FamilyMember)
        expect(assigns(:dependent).family_id).to eq(test_family.id.to_s)
      end

      it "should render the new template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("new")
      end
    end

    describe "with a valid dependent" do
      let(:save_result) { true }

      before :each do
        sign_in(user)
        # No resident role
        allow_any_instance_of(Forms::FamilyMember).to receive(:save).and_return(save_result)
        post :create, params: {dependent: dependent_properties}, :format => "js"
      end

      it "should assign the dependent" do
        expect(assigns(:dependent).class).to eq(Forms::FamilyMember)
        expect(assigns(:dependent).family_id).to eq(test_family.id.to_s)
      end

      it "should assign the created" do
        expect(assigns(:created)).to eq true
      end

      it "should render the show template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("show")
      end
    end

    describe "with a valid dependent but not applying for coverage" do
      let(:save_result) { true }
      let(:dependent_properties) { { "is_applying_coverage" => "false", "same_with_primary" => "true", "family_id" => test_family.id.to_s } }
      let(:test_family) { FactoryBot.create(:family, :with_primary_family_member)}

      before :each do
        sign_in(user)
        # No resident role
        allow_any_instance_of(Forms::FamilyMember).to receive(:save).and_return(save_result)
        post :create, params: {dependent: dependent_properties}, :format => "js"
      end

      it "should assign the dependent" do
        expect(assigns(:dependent).class).to eq ::Forms::FamilyMember
        expect(assigns(:dependent).family_id).to eq(test_family.id.to_s)
      end

      it "should assign the created" do
        expect(assigns(:created)).to eq true
      end

      it "should render the show template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("show")
      end
    end

    describe "when update_vlp_documents failed" do
      before :each do
        sign_in(user)
        allow(controller).to receive(:update_vlp_documents).and_return false
        post :create, params: {dependent: dependent_properties}, :format => "js"
      end

      it "should render the new template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("new")
      end

      it "should get addresses as an array" do
        expect(response).to render_template("new")
        expect(assigns(:dependent).addresses.class).to eq Array
      end
    end

    describe "with a valid dependent but invalid addresses" do
      before :each do
        allow(controller).to receive(:update_vlp_documents).and_return false
        sign_in(user)
        post :create, params: {dependent: dependent_properties}, :format => "js"
      end

      let(:address_errors) {[{:zip => ["Home Addresses: zip should be in the form: 12345 or 12345-1234"]}, {:zip => ["Mailing Addresses: zip should be in the form: 12345 or 12345-1234"]}]}

      let(:dependent) { double(addresses: [invalid_addresses_attributes], family_member: true, same_with_primary: true) }
      let(:dependent_properties) { {addresses: invalid_addresses_attributes, :family_id => test_family.id, same_with_primary: "false" } }
      let!(:test_family) { FactoryBot.create(:family, :with_primary_family_member) }


      it "should assign the dependent" do
        expect(assigns(:dependent).class).to eq Forms::FamilyMember
        expect(assigns(:dependent).family_id).to eq(test_family.id.to_s)
      end

      it "should not assign the created" do
        expect(assigns(:created)).to eq nil
      end

      it "should assign the address_errors" do
        expect(assigns(:address_errors)).to eq address_errors
      end

      it "should render the new template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("new")
      end
    end
  end

  describe "DELETE destroy" do
    let(:dependent) { double }
    let(:dependent_id) { "234dlfjadsklfj" }

    before :each do
      sign_in(user)
    end

    it "should destroy the dependent" do
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
      expect(dependent).to receive(:destroy!)
      delete :destroy, params: {id: dependent_id}
    end

    it "should render the index template" do
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
      allow(dependent).to receive(:destroy!)
      delete :destroy, params: {id: dependent_id}
      expect(response).to have_http_status(:success)
      expect(response).to render_template("index")
    end

    context "Delete Duplicate FM members" do
      let(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent)}
      let(:dependent1) { family.family_members.where(is_primary_applicant: false).first }
      let(:dependent2) { family.family_members.where(is_primary_applicant: false).last }
      let!(:duplicate_family_member_1) do
        family.family_members << FamilyMember.new(person_id: dependent1.person.id)
        dup_fm = family.family_members.last
        dup_fm.save(validate: false)
        dup_fm
      end
      let!(:duplicate_family_member_2) do
        family.family_members << FamilyMember.new(person_id: dependent1.person.id)
        dup_fm = family.family_members.last
        dup_fm.save(validate: false)
        dup_fm
      end

      it 'should destroy the duplicate dependents if exists' do
        expect(family.family_members.active.count).to eq 5
        delete :destroy, params: {id: dependent1.id}
        expect(response).to have_http_status(:success)
        family.reload
        expect(family.family_members.active.count).to eq 3
      end

    end
  end

  describe "GET edit" do
    let(:dependent) { double(family_member: double) }
    let(:dependent_id) { "234dlfjadsklfj" }

    before :each do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
      get :edit, params: {id: dependent_id}
    end

    it "should assign the dependent" do
      expect(assigns(:dependent)).to eq dependent
    end

    it "should render the edit template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("edit")
    end
  end

  describe "PUT update" do
    let(:address) { double }
    let(:family_member) { double }
    let(:valid_addresses_attributes) do
      {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211"},
       "1" => {"kind" => "mailing", "address_1" => "address1_b", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211" } }
    end
    let(:invalid_addresses_attributes) do
      {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "222"},
       "1" => {"kind" => "mailing", "address_1" => "test", "address_2" => "", "city" => "test", "state" => "DC", "zip" => "223"} }
    end
    let(:dependent) { double(addresses: [valid_addresses_attributes], family_member: true, same_with_primary: true) }
    let(:dependent_properties) do
      {
        addresses: valid_addresses_attributes,
        :family_id => test_family.id,
        same_with_primary: true
      }
    end
    let(:invalid_dependent_properties) do
      {
        addresses: invalid_addresses_attributes,
        :family_id => test_family.id,
        same_with_primary: false
      }
    end

    let(:update_result) { false }
    let!(:test_family) { FactoryBot.create(:family, :with_primary_family_member) }

    before(:each) do
      sign_in(user)
    end

    describe "with an invalid dependent" do
      it "should render the edit template" do
        put :update, params: {id: test_family.family_members.last.id.to_s, dependent: invalid_dependent_properties}
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end

      it "addresses should be an array" do
        put :update, params: {id: test_family.family_members.last.id.to_s, dependent: invalid_dependent_properties}
        expect(assigns(:dependent).addresses.class).to eq Array
      end
    end

    describe "with a valid dependent" do
      let(:update_result) { true }
      it "should render the show template" do
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        put :update, params: {id: test_family.family_members.last.id.to_s, dependent: dependent_properties}
        expect(response).to have_http_status(:success)
        expect(response).to render_template("show")
      end

      it "should render the edit template when update_vlp_documents failure" do
        allow(controller).to receive(:update_vlp_documents).and_return(false)
        put :update, params: {id: test_family.family_members.last.id.to_s, dependent: dependent_properties}
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end
    end

    describe "with a valid dependent but invalid addresses" do
      before :each do
        allow(controller).to receive(:update_vlp_documents).and_return false
      end

      let(:address_errors) {[{:zip => ["Home Addresses: zip should be in the form: 12345 or 12345-1234"]}, {:zip => ["Mailing Addresses: zip should be in the form: 12345 or 12345-1234"]}]}

      let(:dependent) { double(addresses: [invalid_addresses_attributes], family_member: true, same_with_primary: true) }
      let(:dependent_properties) { ActionController::Parameters.new({addresses: invalid_addresses_attributes, :family_id => "saldjfalkdjf", same_with_primary: "false" }).permit! }


      it "should render the edit template" do
        put :update, params: {id: test_family.family_members.last.id.to_s, dependent: dependent_properties}
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end

      it "should assign the address_errors" do
        put :update, params: {id: test_family.family_members.last.id.to_s, dependent: dependent_properties}
        expect(assigns(:address_errors)).to eq address_errors
      end
    end
  end
end