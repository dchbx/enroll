# frozen_string_literal: true

module PdfTemplates
  class NoticeAddress
    include Virtus.model

    attribute :street_1, String
    attribute :street_2, String
    attribute :city, String
    attribute :state, String
    attribute :zip, String
  end
end
