# frozen_string_literal: true

module Analytics
  module Dimensions
    class Weekly
      include Mongoid::Document

      field :title, type: String
      field :site,  type: String, default: "dchbx"
      field :topic, type: String
      field :date,  type: Date
      field :week,  type: Integer
      field :year,  type: Integer

      field :d1, type: Integer, default: 0
      field :d2, type: Integer, default: 0
      field :d3, type: Integer, default: 0
      field :d4, type: Integer, default: 0
      field :d5, type: Integer, default: 0
      field :d6, type: Integer, default: 0
      field :d7, type: Integer, default: 0

      index({site: 1, topic: 1, week: 1, year: 1})

      validates_presence_of :site, :topic, :date, :week, :year

      after_initialize :pre_allocate_document

      def increment(new_date)
        week_day  = new_date.wday

        # Use the Mongoid increment (inc) function
        inc("d#{week_day}".to_sym => 1)
        self
      end

      private

      def pre_allocate_document
        self.week = date.cweek if week.blank?

        self.year = date.year if year.blank?
      end
    end
  end
end