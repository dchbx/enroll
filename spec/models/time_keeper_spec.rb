require 'rails_helper'

module TkNotifyWrapper
  class ExpectedLogCallInvoked < StandardError; end

  class SimpleWrapper < SimpleDelegator
    def initialize(obj)
      super(obj)
    end

    def expect_event(e, pay)
      @event = e
      @payload = pay
    end

    def instrument(event, payload)
      if (event == @event && payload == @payload)
        raise ExpectedLogCallInvoked.new
      else 
        super(event,payload)
      end
    end
  end
end

RSpec.describe TimeKeeper, type: :model do

  context "the system initializes" do
    context "and a date_of_record value isn't available in the locally-persisted store" do
      let(:notification_stub) { TkNotifyWrapper::SimpleWrapper.new(ActiveSupport::Notifications) }
      before :each do
        Rails.cache.delete(TimeKeeper::CACHE_KEY)
        stub_const("ActiveSupport::Notifications", notification_stub)
      end

      it "should send a syslog info message to the enterprise logger" do
        notification_stub.expect_event("acapi.info.application.enroll.logging", {:body => "date_of_record not available for TimeKeeper - using Date.current"})
        expect { TimeKeeper.date_of_record }.to raise_error(TkNotifyWrapper::ExpectedLogCallInvoked)
      end

      context "and the date_of_record isn't available from enterprise service" do
        it "should send a syslog critical error to the enterprise logger"
        it "should halt the system initialization process to avoid corrupting records"
      end
    end
  end

  context "a message is received with a new date_of_record" do
    let(:base_date)   { Date.current }
    let(:past_date)   { Date.current - 5.days }
    let(:next_day)    { Date.current + 1.day  }
    let(:future_date) { Date.current + 5.days }

    let(:date_of_record) { TimeKeeper.set_date_of_record(base_date) }

    context "and new date the same as the current date_of_record" do
      it "should leave the date unchanged" do
        expect(TimeKeeper.set_date_of_record(base_date)).to eq date_of_record
      end
    end

    context "and new date is prior to the current date_of_record" do
      # expect(TimeKeeper.set_date_of_record(past_date)).to raise_error(StandardError)

      let(:notification_stub) { TkNotifyWrapper::SimpleWrapper.new(ActiveSupport::Notifications) }
      before :each do
        stub_const("ActiveSupport::Notifications", notification_stub)
      end

      it "should send a syslog critical error to the enterprise logger" do
        notification_stub.expect_event("acapi.error.application.enroll.logging", {:body => "Attempt made to set date to past: #{past_date}"})
        expect { TimeKeeper.set_date_of_record(past_date) }.to raise_error(TkNotifyWrapper::ExpectedLogCallInvoked)
      end
    end

    context "and new date is one day later than current date_of_record" do
      let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
      it "should advance the date" do
        expect(TimeKeeper.set_date_of_record(next_day)).to eq next_day
      end

      it "should send the new date_of_record to registered models"

      it "should persist the new date_of_record in the local data store"
      it "should send a syslog info message to the enterprise logger"
    end

    context "and new date is more than one day later than curent date_of_record" do
      it "should send the new date_of_record to registered models for each day" 
      it "should persist in the local data storage the new date_of_record for each successful advance"
      it "should send a syslog info message to the enterprise logger for each successful advance"
    end
  end

  context "which can avoid local cache hits" do
    before :each do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    it "should return identical values for the life of the cache" do
      first_value = "first value"
      second_value = "second value"
      TimeKeeper.with_cache do
        first_value = TimeKeeper.date_of_record
        second_value = TimeKeeper.date_of_record
      end
      expect(first_value).to eq(second_value)
      expect(first_value).to equal(second_value)
    end
  end
end
