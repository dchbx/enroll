# frozen_string_literal: true

module Analytics
  module Dimensions
    class MinutesOfHour
      include Mongoid::Document

      embedded_in :daily, class_name: "Analytics::Dimensions::Daily"

      field :hour, type: Integer
    ## TODO - add child model to track instance refs
    # field :topic_class_name, type: String
    # field :topic_id, type: BSON::ObjectId

      field :m0,  type: Integer, default: 0
      field :m1,  type: Integer, default: 0
      field :m2,  type: Integer, default: 0
      field :m3,  type: Integer, default: 0
      field :m4,  type: Integer, default: 0
      field :m5,  type: Integer, default: 0
      field :m6,  type: Integer, default: 0
      field :m7,  type: Integer, default: 0
      field :m8,  type: Integer, default: 0
      field :m9,  type: Integer, default: 0

      field :m10, type: Integer, default: 0
      field :m11, type: Integer, default: 0
      field :m12, type: Integer, default: 0
      field :m13, type: Integer, default: 0
      field :m14, type: Integer, default: 0
      field :m15, type: Integer, default: 0
      field :m16, type: Integer, default: 0
      field :m17, type: Integer, default: 0
      field :m18, type: Integer, default: 0
      field :m19, type: Integer, default: 0

      field :m20, type: Integer, default: 0
      field :m21, type: Integer, default: 0
      field :m22, type: Integer, default: 0
      field :m23, type: Integer, default: 0
      field :m24, type: Integer, default: 0
      field :m25, type: Integer, default: 0
      field :m26, type: Integer, default: 0
      field :m27, type: Integer, default: 0
      field :m28, type: Integer, default: 0
      field :m29, type: Integer, default: 0

      field :m30, type: Integer, default: 0
      field :m31, type: Integer, default: 0
      field :m32, type: Integer, default: 0
      field :m33, type: Integer, default: 0
      field :m34, type: Integer, default: 0
      field :m35, type: Integer, default: 0
      field :m36, type: Integer, default: 0
      field :m37, type: Integer, default: 0
      field :m38, type: Integer, default: 0
      field :m39, type: Integer, default: 0

      field :m40, type: Integer, default: 0
      field :m41, type: Integer, default: 0
      field :m42, type: Integer, default: 0
      field :m43, type: Integer, default: 0
      field :m44, type: Integer, default: 0
      field :m45, type: Integer, default: 0
      field :m46, type: Integer, default: 0
      field :m47, type: Integer, default: 0
      field :m48, type: Integer, default: 0
      field :m49, type: Integer, default: 0

      field :m50, type: Integer, default: 0
      field :m51, type: Integer, default: 0
      field :m52, type: Integer, default: 0
      field :m53, type: Integer, default: 0
      field :m54, type: Integer, default: 0
      field :m55, type: Integer, default: 0
      field :m56, type: Integer, default: 0
      field :m57, type: Integer, default: 0
      field :m58, type: Integer, default: 0
      field :m59, type: Integer, default: 0

      validates_presence_of :hour

    end
  end
end