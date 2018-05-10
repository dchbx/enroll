require 'rails_helper'

RSpec.describe ScheduledEvent, type: :model do
  subject { ScheduledEvent.new }

  it "has a valid factory" do
    expect(create(:scheduled_event)).to be_valid
  end

  it { is_expected.to validate_presence_of :type }
  it { is_expected.to validate_presence_of :event_name }
  it { is_expected.to validate_presence_of :one_time }
  it { is_expected.to validate_presence_of :start_time }

  context "convert recurring rules into hash" do
  	let(:event_params) { {
      type: 'holiday',
      event_name: 'Christmas',
      offset_rule: 3,
      recurring_rules: "{\"interval\":1,\"until\":null,\"count\":null,\"validations\":{\"day_of_week\":{},\"day_of_month\":[22]},\"rule_type\":\"IceCube::MonthlyRule\",\"week_start\":0}",
      :start_time => Date.today
    }}
    value = "{\"interval\":1,\"until\":null,\"count\":null,\"validations\":{\"day_of_week\":{},\"day_of_month\":[22]},\"rule_type\":\"IceCube::MonthlyRule\",\"week_start\":0}"
  	let(:scheduled_event1) {ScheduledEvent.new(event_params)}
  	recurring_hash = {:validations=>{:day_of_month=>[22]}, :rule_type=>"IceCube::MonthlyRule", :interval=>1}
  	it "convert recurring rules into hash" do
  	  expect(scheduled_event1.recurring_rules).to eq recurring_hash
  	end
  end

  context "set start time to current if entered value is blank" do
  	value = ""
  	let(:event_params) { {
      type: 'holiday',
      event_name: 'Christmas',
      offset_rule: 3,
      recurring_rules: "{\"interval\":1,\"until\":null,\"count\":null,\"validations\":{\"day_of_week\":{},\"day_of_month\":[22]},\"rule_type\":\"IceCube::MonthlyRule\",\"week_start\":0}",
      :start_time => value
    }}
  	let(:scheduled_event1) {ScheduledEvent.new(event_params)}
  	it "set start time to current if entered value is blank" do
  	  expect(scheduled_event1.start_time).to eq TimeKeeper.date_of_record
  	end
  end

  context "set start time value is entered" do
  	value = "05/24/2017"
  	let(:event_params) { {
      type: 'holiday',
      event_name: 'Christmas',
      offset_rule: 3,
      recurring_rules: "{\"interval\":1,\"until\":null,\"count\":null,\"validations\":{\"day_of_week\":{},\"day_of_month\":[22]},\"rule_type\":\"IceCube::MonthlyRule\",\"week_start\":0}",
      :start_time => value
    }}
  	let(:scheduled_event1) {ScheduledEvent.new(event_params)}
  	it "set start time value is entered" do
  	  expect(scheduled_event1.start_time).to eq Date.strptime(value, "%m/%d/%Y").to_date
  	end
  end
  
  context "Calendar Event" do
    let(:schedule_event_with_empty_recurring_rules) { FactoryGirl.create(:scheduled_event, :empty_recurring_rules, offset_rule: 3)}
    let(:scheduled_event_recurring_rules) { FactoryGirl.create(:scheduled_event, :empty_recurring_rules, offset_rule: 3)}
    let(:friday_offset_1) { FactoryGirl.create(:scheduled_event, :start_on_friday, offset_rule: 1)}
    let(:friday_offset_2) { FactoryGirl.create(:scheduled_event, :start_on_friday, offset_rule: 2) }
    let(:sunday_offset_1) { FactoryGirl.create(:scheduled_event, :start_on_sunday, offset_rule: 1) }
    let(:saturday_offset_1) { FactoryGirl.create(:scheduled_event, :start_on_saturday, offset_rule: 4) }

    it "should get self event" do
      array = schedule_event_with_empty_recurring_rules.calendar_events(schedule_event_with_empty_recurring_rules.start_time, 4)
      expect(array.length).to eq 1
      expect(array).to eq [schedule_event_with_empty_recurring_rules]
    end

    it "should get same start time for self event" do
      array = schedule_event_with_empty_recurring_rules.calendar_events(schedule_event_with_empty_recurring_rules.start_time, 4)
      expect(array.length).to eq 1
      expect(array.collect(&:start_time)).to eq [schedule_event_with_empty_recurring_rules.start_time]
    end

    it "should get 3 occurences" do
      array = scheduled_event_recurring_rules.calendar_events(scheduled_event_recurring_rules.start_time, 4)
      expect(array.length).to eq 1
      expect(array.collect(&:start_time)).to eq [scheduled_event_recurring_rules.start_time]
    end

    it "should not reschedule for weekday for any offset" do
      events = friday_offset_1.calendar_events(friday_offset_1.start_time, friday_offset_1.offset_rule)
      expect(events.first.start_time.strftime('%A')).to eq 'Friday'
    end

    it "should reschedule to Tuesday for Sunday scheduled Event with offset 2" do
      events = friday_offset_2.calendar_events(friday_offset_2.start_time, friday_offset_2.offset_rule)
      expect(events.first.start_time.strftime('%A')).to eq 'Friday'
    end

    it "should reschedule to Monday for Sunday scheduled Event with offset 1" do
      sunday_offset_1.update_attributes(recurring_rules: "{\"interval\":1,\"until\":null,\"count\":null,\"validations\":{\"day_of_week\":{},\"day_of_month\":[#{Date.today.sunday.day}]},\"rule_type\":\"IceCube::MonthlyRule\",\"week_start\":0}")
      events = sunday_offset_1.calendar_events(sunday_offset_1.start_time, sunday_offset_1.offset_rule)
      expect(events.first.start_time.strftime('%A')).to eq 'Monday'
    end

    it "should reschedule to Thursday for Saturday scheduled Event with offset 4" do
      saturday_offset_1.update_attributes(recurring_rules: "{\"interval\":1,\"until\":null,\"count\":null,\"validations\":{\"day_of_week\":{},\"day_of_month\":[#{(Date.today.sunday + 6.day).day}]},\"rule_type\":\"IceCube::MonthlyRule\",\"week_start\":0}")
      events = saturday_offset_1.calendar_events(saturday_offset_1.start_time, saturday_offset_1.offset_rule)
      expect(events.first.start_time.strftime('%A')).to eq 'Thursday'
    end
  end
end
