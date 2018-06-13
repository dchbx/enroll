require 'rails_helper'

RSpec.describe Exchanges::ScheduledEventsController do

  let(:user){ double(:save => double("user")) }
  let(:person) { FactoryGirl.create(:person) }
  let(:event_params) { {
      type: 'holiday',
      event_name: 'Christmas',
      offset_rule: 3,
      recurring_rules: {},
      :start_time => Date.today
    }}
  after do
    ScheduledEvent.delete_all
  end
  before do
    sign_in(user)
  end

  describe "GET new" do
	  it "should render the new template" do
  	  xhr :get, :new
        expect(response).to have_http_status(:success)
      end
  end

  describe "Create Post" do
    let(:scheduled_event) { double(:scheduled_event, recurring_rules: false, errors: errors) }
    let(:success) { true }
    let(:errors) { [] }
    before do
      allow(ScheduledEvent).to receive(:new).and_return(scheduled_event)
      allow(scheduled_event).to receive(:save!).and_return success
      xhr :post, :create, scheduled_event: event_params
    end
  	it "returns http status" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template('exchanges/scheduled_events/create')
    end
    context "for an invalid update" do
      let(:success) { false }
      let(:errors) { double(values: ['failure message']) }
      it "should render new template when invalid params" do
        expect(assigns(:flash_type)).to eq('error')
        expect(response).to have_http_status(:success)
        expect(response).to render_template('exchanges/scheduled_events/new')
      end
    end
  end

  describe "destroy" do
    let(:scheduled_event) { FactoryGirl.create(:scheduled_event) }
    before :each do
      xhr :delete, :destroy, id: scheduled_event.id
    end
    it "redirects_to index page" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template('exchanges/scheduled_events/destroy')
    end
  end

  describe "update" do
    context "remove event exceptions" do
      let!(:event_exception) { FactoryGirl.create(:event_exception) }
      let!(:scheduled_event) { ScheduledEvent.all.first }
      it "delete event exceptions" do
        xhr :put, :update, id: scheduled_event.id, scheduled_event: event_params
        expect(ScheduledEvent.all.first.event_exceptions.length).to eq 0
        expect(response).to have_http_status(:success)
        expect(response).to render_template('exchanges/scheduled_events/list')
      end
    end
    context "Add recurring rules" do
      let!(:scheduled_event) { FactoryGirl.create(:scheduled_event) }
      it "set one time false with recurring rules" do
        scheduled_event.update_attributes!(recurring_rules: "{\"interval\":1,\"until\":null,\"count\":null,\"validations\":{\"day_of_week\":{},\"day_of_month\":[22]},\"rule_type\":\"IceCube::MonthlyRule\",\"week_start\":0}")
        xhr :put, :update, id: scheduled_event.id, scheduled_event: event_params
        expect(scheduled_event.one_time).to eq true
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET index" do
    let(:scheduled_event) { FactoryGirl.create(:scheduled_event) }
    let(:scheduled_events) { [scheduled_event] }
    it 'assigns scheduled_events' do
      xhr :get, :index, scheduled_event: event_params
      expect(assigns[:scheduled_events]).to_not be_nil
    end
  end

  describe "GET#current_events" do
    before do
      get :current_events, event: 'system'
    end

    it "should return supported events" do
      expect(response).to render_template(:'exchanges/scheduled_events/_get_events_field')
      expect(assigns(:events)).to match_array(["binder_payment_due_date", "ivl_monthly_open_enrollment_due_on", "publish_due_date_of_month",
                                               "shop_group_file_new_enrollment_transmit_on", "shop_group_file_update_transmit_day_of_week",
                                               "shop_initial_application_publish_due_day_of_month", "shop_open_enrollment_monthly_end_on",
                                               "shop_renewal_application_force_publish_day_of_month", "shop_renewal_application_monthly_open_enrollment_end_on",
                                               "shop_renewal_application_publish_due_day_of_month"])
    end
  end

  describe "POST#delete_current_event" do
    let(:scheduled_event) { FactoryGirl.create(:scheduled_event) }
    let(:time) { Date.new(2017, 8, 22) }
    before do
      scheduled_event.update_attributes!(recurring_rules: "{\"interval\":1,\"until\":null,\"count\":null,\"validations\":{\"day_of_week\":{},\"day_of_month\":[22]},\"rule_type\":\"IceCube::MonthlyRule\",\"week_start\":0}")
      xhr :post, :delete_current_event, id: scheduled_event.id, time: time
    end
    it "should create an exception" do
      expect(ScheduledEvent.all.first.event_exceptions.length).to eq 1
      expect(ScheduledEvent.all.first.event_exceptions.first.time.day).to eq 22
      expect(ScheduledEvent.all.first.event_exceptions.first.time.month).to eq 8
      expect(ScheduledEvent.all.first.event_exceptions.first.time.year).to eq 2017
      expect(response).to have_http_status(:success)
    end
  end
end
