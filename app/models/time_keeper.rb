class TimeKeeper
  include Mongoid::Document
  include Singleton
  include Acapi::Notifiers
  extend Acapi::Notifiers

  CACHE_KEY = "timekeeper/date_of_record"

  # time zone management

  def initialize
  end

  def self.date_according_to_exchange_at(a_time)
    a_time.in_time_zone("Eastern Time (US & Canada)").to_date
  end

  def self.set_date_of_record(new_date)
    new_date = new_date.to_date
    if instance.date_of_record != new_date
      if instance.date_of_record > new_date
        log("Attempt made to set date to past: #{new_date}", {:severity => :error})
        raise StandardError, "system may not go backward in time"
      else
        number_of_days = (new_date - instance.date_of_record).to_i
        number_of_days.times do
          instance.set_date_of_record(instance.date_of_record + 1.day)
          instance.push_date_of_record
        end
      end
    end
    instance.date_of_record
  end

  # DO NOT EVER USE OUTSIDE OF TESTS
  def self.set_date_of_record_unprotected!(new_date)
    new_date = new_date.to_date
    if instance.date_of_record != new_date
      (new_date - instance.date_of_record).to_i
      instance.set_date_of_record(new_date)
    end
    instance.date_of_record
  end

  def self.date_of_record
    instance.date_of_record
  end

  def self.datetime_of_record
    instant = Time.current
    instance.date_of_record.to_datetime + instant.hour.hours + instant.min.minutes + instant.sec.seconds
  end

  def set_date_of_record(new_date)
    Rails.cache.write(CACHE_KEY, new_date.strftime("%Y-%m-%d"))
  end

  def date_of_record
    tl_value = thread_local_date_of_record
    return tl_value unless tl_value.blank?
    found_value = Rails.cache.fetch(CACHE_KEY) do
      log("date_of_record not available for TimeKeeper - using Date.current")
      Date.current.strftime("%Y-%m-%d")
    end
    Date.strptime(found_value, "%Y-%m-%d")
  end

  def push_date_of_record
    BenefitSponsorship.advance_day(self.date_of_record)
    EmployerProfile.advance_day(self.date_of_record)
    Family.advance_day(self.date_of_record)
    HbxEnrollment.advance_day(self.date_of_record)
    CensusEmployee.advance_day(self.date_of_record)
    ConsumerRole.advance_day(self.date_of_record)
  end

  def self.with_cache
    Thread.current[:time_keeper_local_cached_date] = date_of_record
    yield
    Thread.current[:time_keeper_local_cached_date] = nil
  end

  def thread_local_date_of_record
    Thread.current[:time_keeper_local_cached_date]
  end
end
