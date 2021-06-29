# frozen_string_literal: true

module Analytics
  module Dimensions
    class Daily
      include Mongoid::Document

      field :title,   type: String
      field :site,    type: String, default: "dchbx"
      field :topic,   type: String
      field :date,    type: Date
      field :week_day, type: Integer

      index({site: 1, topic: 1, date: 1, :"hours_of_day.hour" => 1})
      index({site: 1, topic: 1, week_day: 1})

      embeds_one  :hours_of_day,     class_name: "Analytics::Dimensions::HoursOfDay"
      embeds_many :minutes_of_hours, class_name: "Analytics::Dimensions::MinutesOfHour"

      accepts_nested_attributes_for :hours_of_day, :minutes_of_hours

      after_initialize :pre_allocate_document

      validates_presence_of :site, :topic, :date, :week_day

      def increment(time_stamp)
        hour    = time_stamp.hour
        minute  = time_stamp.min

        hours_of_day.inc("h#{hour}".to_sym => 1)
        minutes_of_hours.where("hour" => hour.to_s).first.inc("m#{minute}".to_sym => 1)
        self
      end

      private

      def pre_allocate_document
        self.build_hours_of_day unless hours_of_day.present?

        self.week_day = date.wday if week_day.blank?

        (0..23).map { |i| self.minutes_of_hours << Analytics::Dimensions::MinutesOfHour.new(hour: i) } if minutes_of_hours.empty?
      end

    end
  end
end