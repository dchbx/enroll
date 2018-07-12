require 'rails_helper'

describe "ScheduledEventService"  do

  context "Individual market kind" do

    it "should return settings day" do
      expect(ScheduledEvent.individual_market_monthly_enrollment_due_on).to eq Setting.individual_market_monthly_enrollment_due_on
    end

    it "should return day from variable" do
      expect(ScheduledEvent.instance_variable_get(:@individual_market_monthly_enrollment_due_on)).to eq Setting.individual_market_monthly_enrollment_due_on
    end

    it "should return from scheduled_event day" do
      ScheduledEvent.instance_variable_set(:@individual_market_monthly_enrollment_due_on,nil)
      scheduled_event = FactoryGirl.create(:scheduled_event,{ :event_name => 'ivl_monthly_enrollment_due_on'})
      expect(ScheduledEvent.individual_market_monthly_enrollment_due_on).to eq scheduled_event.start_time.day
    end

  end

  context "Shop market binder payment due_on" do

    it "should return settings day" do
      expect(ScheduledEvent.shop_market_binder_payment_due_on).to eq Settings.aca.shop_market.binder_payment_due_on
    end

    it "should return day from variable" do
      expect(ScheduledEvent.instance_variable_get(:@shop_market_binder_payment_due_on)).to eq Settings.aca.shop_market.binder_payment_due_on
    end

    it "should return from scheduled_event day" do
      ScheduledEvent.instance_variable_set(:@shop_market_binder_payment_due_on,nil)
      scheduled_event = FactoryGirl.create(:scheduled_event,{ :event_name => 'shop_binder_payment_due_on'})
      expect(ScheduledEvent.shop_market_binder_payment_due_on).to eq scheduled_event.start_time.day
    end

  end

  context "Shop market initial application publish due day of month" do

    it "should return settings day" do
      expect(ScheduledEvent.shop_market_initial_application_publish_due_day_of_month).to eq Settings.aca.shop_market.initial_application.publish_due_day_of_month
    end

    it "should return day from variable" do
      expect(ScheduledEvent.instance_variable_get(:@shop_market_initial_application_publish_due_day_of_month)).to eq Settings.aca.shop_market.initial_application.publish_due_day_of_month
    end

    it "should return from scheduled_event day" do
      ScheduledEvent.instance_variable_set(:@shop_market_initial_application_publish_due_day_of_month,nil)
      scheduled_event = FactoryGirl.create(:scheduled_event,{ :event_name => 'shop_initial_application_publish_due_day_of_month'})
      expect(ScheduledEvent.shop_market_initial_application_publish_due_day_of_month).to eq scheduled_event.start_time.day
    end

  end

  context "Shop market renewal application monthly open enrollment end on" do

    it "should return settings day" do
      expect(ScheduledEvent.shop_market_renewal_application_monthly_open_enrollment_end_on).to eq Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on
    end

    it "should return day from variable" do
      expect(ScheduledEvent.instance_variable_get(:@shop_market_renewal_application_monthly_open_enrollment_end_on)).to eq Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on
    end

    it "should return from scheduled_event day" do
      ScheduledEvent.instance_variable_set(:@shop_market_renewal_application_monthly_open_enrollment_end_on,nil)
      scheduled_event = FactoryGirl.create(:scheduled_event,{ :event_name => 'shop_renewal_application_monthly_open_enrollment_end_on'})
      expect(ScheduledEvent.shop_market_renewal_application_monthly_open_enrollment_end_on).to eq scheduled_event.start_time.day
    end

  end


  context "Shop market renewal application publish due day of month" do

    it "should return settings day" do
      expect(ScheduledEvent.shop_market_renewal_application_publish_due_day_of_month).to eq Settings.aca.shop_market.renewal_application.publish_due_day_of_month
    end

    it "should return day from variable" do
      expect(ScheduledEvent.instance_variable_get(:@shop_market_renewal_application_publish_due_day_of_month)).to eq Settings.aca.shop_market.renewal_application.publish_due_day_of_month
    end

    it "should return from scheduled_event day" do
      ScheduledEvent.instance_variable_set(:@shop_market_renewal_application_publish_due_day_of_month,nil)
      scheduled_event = FactoryGirl.create(:scheduled_event,{ :event_name => 'shop_renewal_application_publish_due_day_of_month'})
      expect(ScheduledEvent.shop_market_renewal_application_publish_due_day_of_month).to eq scheduled_event.start_time.day
    end

  end

  context "Shop market renewal application Publish Anyways day of month" do

    it "should return settings day" do
      expect(ScheduledEvent.shop_market_renewal_application_force_publish_day_of_month).to eq Settings.aca.shop_market.renewal_application.force_publish_day_of_month
    end

    it "should return day from variable" do
      expect(ScheduledEvent.instance_variable_get(:@shop_market_renewal_application_force_publish_day_of_month)).to eq Settings.aca.shop_market.renewal_application.force_publish_day_of_month
    end

    it "should return from scheduled_event day" do
      ScheduledEvent.instance_variable_set(:@shop_market_renewal_application_force_publish_day_of_month,nil)
      scheduled_event = FactoryGirl.create(:scheduled_event,{ :event_name => 'shop_renewal_application_force_publish_day_of_month'})
      expect(ScheduledEvent.shop_market_renewal_application_force_publish_day_of_month).to eq scheduled_event.start_time.day
    end

  end

  context "Shop market open enrollment monthly end on" do

    it "should return settings day" do
      expect(ScheduledEvent.shop_market_open_enrollment_monthly_end_on).to eq Settings.aca.shop_market.open_enrollment.monthly_end_on
    end

    it "should return day from variable" do
      expect(ScheduledEvent.instance_variable_get(:@shop_market_open_enrollment_monthly_end_on)).to eq Settings.aca.shop_market.open_enrollment.monthly_end_on
    end

    it "should return from scheduled_event day" do
      ScheduledEvent.instance_variable_set(:@shop_market_open_enrollment_monthly_end_on,nil)
      scheduled_event = FactoryGirl.create(:scheduled_event,{ :event_name => 'shop_open_enrollment_monthly_end_on'})
      expect(ScheduledEvent.shop_market_open_enrollment_monthly_end_on).to eq scheduled_event.start_time.day
    end

  end

  context "Shop market group file new enrollment transmit on" do

    it "should return settings day" do
      expect(ScheduledEvent.shop_market_group_file_new_enrollment_transmit_on).to eq Settings.aca.shop_market.group_file.new_enrollment_transmit_on
    end

    it "should return day from variable" do
      expect(ScheduledEvent.instance_variable_get(:@shop_market_group_file_new_enrollment_transmit_on)).to eq Settings.aca.shop_market.group_file.new_enrollment_transmit_on
    end

    it "should return from scheduled_event day" do
      ScheduledEvent.instance_variable_set(:@shop_market_group_file_new_enrollment_transmit_on,nil)
      scheduled_event = FactoryGirl.create(:scheduled_event,{ :event_name => 'shop_group_file_new_enrollment_transmit_on'})
      expect(ScheduledEvent.shop_market_group_file_new_enrollment_transmit_on).to eq scheduled_event.start_time.day
    end

  end

  context "Shop market group file update transmit day of week" do

    it "should return settings day" do
      expect(ScheduledEvent.shop_market_group_file_update_transmit_day_of_week).to eq Settings.aca.shop_market.group_file.update_transmit_day_of_week
    end

    it "should return day from variable" do
      expect(ScheduledEvent.instance_variable_get(:@shop_market_group_file_update_transmit_day_of_week)).to eq Settings.aca.shop_market.group_file.update_transmit_day_of_week
    end

    it "should return from scheduled_event day" do
      ScheduledEvent.instance_variable_set(:@shop_market_group_file_update_transmit_day_of_week,nil)
      scheduled_event = FactoryGirl.create(:scheduled_event,{ :event_name => 'shop_group_file_update_transmit_day_of_week'})
      expect(ScheduledEvent.shop_market_group_file_update_transmit_day_of_week).to eq scheduled_event.start_time.day
    end

  end

end