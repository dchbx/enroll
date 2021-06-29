# frozen_string_literal: true

module Analytics
  module Dimensions
    class HoursOfDay
      include Mongoid::Document

      embedded_in :daily, class_name: "Analytics::Dimensions::Daily"

      field :h0,  type: Integer, default: 0
      field :h1,  type: Integer, default: 0
      field :h2,  type: Integer, default: 0
      field :h3,  type: Integer, default: 0
      field :h4,  type: Integer, default: 0
      field :h5,  type: Integer, default: 0
      field :h6,  type: Integer, default: 0
      field :h7,  type: Integer, default: 0
      field :h8,  type: Integer, default: 0
      field :h9,  type: Integer, default: 0
      field :h10, type: Integer, default: 0
      field :h11, type: Integer, default: 0
      field :h12, type: Integer, default: 0
      field :h13, type: Integer, default: 0
      field :h14, type: Integer, default: 0
      field :h15, type: Integer, default: 0
      field :h16, type: Integer, default: 0
      field :h17, type: Integer, default: 0
      field :h18, type: Integer, default: 0
      field :h19, type: Integer, default: 0
      field :h20, type: Integer, default: 0
      field :h21, type: Integer, default: 0
      field :h22, type: Integer, default: 0
      field :h23, type: Integer, default: 0

    end
  end
end