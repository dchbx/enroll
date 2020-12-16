# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Exchanges::EmployerApplicationsController, dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:employer_profile) { benefit_sponsorship.profile }
  let(:person1) { FactoryBot.create(:person) }

  describe ".index" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true, :person => person1) }

    before :each do
      sign_in(user)
      get :index, params: { employers_action_id: "employers_action_#{employer_profile.id}", employer_id: benefit_sponsorship }, xhr: true
    end

    it "should render index" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/employer_applications/index")
    end

    context 'when hbx staff role missing' do
      let(:user) { instance_double("User", :has_hbx_staff_role? => false, :person => person1) }

      it 'should redirect when hbx staff role missing' do
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/')
      end
    end
  end

  describe "PUT terminate" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true, :person => person1) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person1) }

    context "when user has permissions" do
      before :each do
        allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', can_modify_plan_year: true))
        sign_in(user)
        put :terminate, params: { employer_application_id: initial_application.id, employer_id: benefit_sponsorship.id, end_on: TimeKeeper.date_of_record.next_month.end_of_month, term_reason: 'nonpayment' }
      end

      it "should be success" do
        expect(response).to have_http_status(:success)
      end

      it "should terminate the plan year" do
        initial_application.reload
        expect(initial_application.aasm_state).to eq :termination_pending
        expect(flash[:notice]).to eq "#{benefit_sponsorship.organization.legal_name}'s Application terminated successfully."
      end
    end

    it "should not be a success when user doesn't have permissions" do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', can_modify_plan_year: false))
      sign_in(user)
      put :terminate, params: { employer_application_id: initial_application.id, employer_id: benefit_sponsorship.id, end_on: initial_application.start_on.next_month, term_reason: 'nonpayment' }
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to match(/Access not allowed/)
    end

    unless allow_mid_month_voluntary_terms? || allow_mid_month_non_payment_terms?
      context 'non-mid month terminations' do

        before :each do
          allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', can_modify_plan_year: true))
          sign_in(user)
          put :terminate, params: { employer_application_id: initial_application.id, employer_id: benefit_sponsorship.id, end_on: TimeKeeper.date_of_record.next_month.end_of_month.prev_day, term_reason: 'nonpayment', term_kind: 'nonpayment' }
        end

        it 'should display appropriate error message' do
          expect(flash[:error]).to eq "#{benefit_sponsorship.organization.legal_name}'s Application could not be terminated: Exchange doesn't allow mid month non payment terminations"
        end
      end
    end
  end

  describe "PUT cancel" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true, :person => person1) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person1) }

    context "when user has permissions" do
      before :each do
        allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', can_modify_plan_year: true))
        sign_in(user)
        initial_application.update_attributes!(:aasm_state => :enrollment_open)
        put :cancel, params: { employer_application_id: initial_application.id, employer_id: benefit_sponsorship.id, end_on: initial_application.start_on.next_month }
      end

      it "should be success" do
        expect(response).to have_http_status(:success)
      end

      it "should cancel the plan year" do
        initial_application.reload
        expect(initial_application.aasm_state).to eq :canceled
        expect(flash[:notice]).to eq "#{benefit_sponsorship.organization.legal_name}'s Application canceled successfully."
      end
    end

    it "should not be a success when user doesn't have permissions" do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', can_modify_plan_year: false))
      sign_in(user)
      put :cancel, params: { employer_application_id: initial_application.id, employer_id: benefit_sponsorship.id, end_on: initial_application.start_on.next_month }
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to match(/Access not allowed/)
    end
  end

  describe "get term reasons" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true, :person => person1) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person1) }

    before :each do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', can_modify_plan_year: true))
      sign_in(user)
      get :term_reasons, params: { reason_type_id: "term_actions_nonpayment" },  format: :js
    end

    it "should be success" do
      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT reinstate" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true, :person => person1) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person1) }

    context "when user has permissions" do
      before :each do
        allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', can_modify_plan_year: true))
        sign_in(user)
        initial_application.update_attributes!(:aasm_state => :retroactive_cancel)
        put :reinstate, params: { employer_application_id: initial_application.id, employer_id: benefit_sponsorship.id}
      end

      it "should be success" do
        expect(response).to have_http_status(:success)
      end

      it "should cancel the plan year" do
        initial_application.reload
        expect(initial_application.aasm_state).to eq :retroactive_cancel
        expect(flash[:notice]).to eq "#{benefit_sponsorship.organization.legal_name} - Plan Year Reinstated Successfully Effective #{initial_application.effective_period.min}"
      end
    end
  end
end