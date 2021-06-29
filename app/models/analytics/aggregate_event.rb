# frozen_string_literal: true

module Analytics
  class AggregateEvent

    # accepts_nested_attributes_for :days_of_month, :hours_of_day

    AVERAGE_EVENTS_PER_DAY = 50
    DCHBX_EPOCH = Date.new(2015,10,12).beginning_of_day

    def probabaliistic_preallocate?
      probability = 1.0 / AVERAGE_EVENTS_PER_DAY
      rand(0.0..1.0) < probability
    end

    def self.topic_count_daily(topic: nil, start_on: DCHBX_EPOCH, end_on: TimeKeeper.date_of_record.end_of_day, site: "dchbx")
      Analytics::Dimensions::Daily.where(
        site: site,
        topic: topic,
        "date.gte" => start_on,
        "date.lte" => end_on
      ).sort(date: 1).to_a
    end

    def self.topic_count_weekly(topic: nil, start_on: DCHBX_EPOCH, end_on: TimeKeeper.date_of_record.end_of_day, site: "dchbx")
      Analytics::Dimensions::Weekly.where(
        site: site,
        topic: topic,
        "date.gte" => start_on,
        "date.lte" => end_on
      ).sort(date: 1).to_a
    end

    def self.topic_count_monthly(topic: nil, start_on: DCHBX_EPOCH, end_on: TimeKeeper.date_of_record.end_of_day, site: "dchbx")
      Analytics::Dimensions::Monthly.where(
        site: site,
        topic: topic,
        "date.gte" => start_on,
        "date.lte" => end_on
      ).sort(date: 1).to_a
    end

    def self.increment_time(topic: nil, moment: TimeKeeper.datetime_of_record, site: "dchbx")
      month     = moment.month
      week      = moment.to_date.cweek
      year      = moment.to_date.year

      raise ArgumentError, "missing value: topic, expected as keyword " if topic.blank?

      # Update daily stats
      daily_docs = Analytics::Dimensions::Daily.where(site: site, topic: topic, date: moment)

      daily_instance = if daily_docs.empty?
                         Analytics::Dimensions::Daily.new(site: site, topic: topic, date: moment)
                       else
                         daily_docs.first
                       end

      # Update weekly stats
      weekly_docs = Analytics::Dimensions::Weekly.where(site: site, topic: topic, week: week, year: year)
      weekly_instance = if weekly_docs.empty?
                          Analytics::Dimensions::Weekly.new(site: site, topic: topic, week: week, year: year, date: moment)
                        else
                          weekly_docs.first
                        end

      # Update monthly stats
      monthly_docs = Analytics::Dimensions::Monthly.where(site: site, topic: topic, month: month, year: year)
      monthly_instance = if monthly_docs.empty?
                           Analytics::Dimensions::Monthly.new(site: site, topic: topic, month: month, year: year, date: moment)
                         else
                           monthly_docs.first
                         end

      daily_instance.increment(moment)
      weekly_instance.increment(moment)
      monthly_instance.increment(moment)

      if daily_instance.save && weekly_instance.save && monthly_instance.save
        [daily_instance, weekly_instance, monthly_instance]
      else
        raise StandardError, "update failed, unable to save one or more time dimensions " [daily_instance, weekly_instance, monthly_instance]
      end
    end

    # TODO
    def self.increment_geography(topic, site: "dchbx"); end

  end
end
