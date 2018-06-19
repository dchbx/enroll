require "#{Rails.root}/spec/support/federal_holidays_helper.rb"
include FederalHolidaysHelper

namespace :load_federal_holidays do
  desc "load federal holioday from xlsx file"
  task :update_federal_holidays => :environment do 
    begin
      ScheduledEvent.find_or_create_by!(
          type: 'federal',
          event_name: 'Martin Luther King Jr Birthday',
          offset_rule: 0,
          start_time: nth_wday(3, 1, 1, Date.today.year)
          )
      ScheduledEvent.find_or_create_by!(
          type: 'federal',
          event_name: "President's Day",
          offset_rule: 0,
          start_time: nth_wday(3, 1, 2, Date.today.year)
          )
      ScheduledEvent.find_or_create_by!(
          type: 'federal',
          event_name: 'Memorial Day',
          offset_rule: 0,
          start_time: last_monday_may(Date.today.year, 5, 31)
          )
      ScheduledEvent.find_or_create_by!(
          type: 'federal',
          event_name: 'Labor Day',
          offset_rule: 0,
          start_time: nth_wday(1, 1, 9, Date.today.year)
          )
      ScheduledEvent.find_or_create_by!(
          type: 'federal',
          event_name: 'Columbus Day',
          offset_rule: 0,
          start_time: nth_wday(2, 1, 10, Date.today.year)
          )
      ScheduledEvent.find_or_create_by!(
          type: 'federal',
          event_name: 'Thanksgiving Day',
          offset_rule: 0,
          start_time: nth_wday(4, 4, 11, Date.today.year)
          )
      ScheduledEvent.find_or_create_by!(
          type: 'federal',
          event_name: 'Veterans Day',
          offset_rule: 0,
          start_time: schedule_time(Date.new(Date.today.year, 11, 11))
          )
      ScheduledEvent.find_or_create_by!(
          type: 'federal',
          event_name: 'New Year Day',
          offset_rule: 0,
          start_time: schedule_time(Date.new(Date.today.year, 01, 01))
          )
      ScheduledEvent.find_or_create_by!(
          type: 'federal',
          event_name: 'Christmas Day',
          offset_rule: 0,
          start_time: schedule_time(Date.new(Date.today.year, 12, 25))
          )
      ScheduledEvent.find_or_create_by!(
          type: 'federal',
          event_name: 'Independence Day',
          offset_rule: 0,
          start_time: schedule_time(Date.new(Date.today.year, 07, 04))
          )
    rescue => e
      puts e.inspect
    end
  end

end