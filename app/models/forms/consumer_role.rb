# frozen_string_literal: true

module Forms
  class ConsumerRole < SimpleDelegator
    include ActiveModel::Validations

    attr_accessor :vlp_document_kind, :doc_number

    validates_presence_of :doc_number, :vlp_document_kind

    def self.model_name
      Person.model_name
    end

  end
end
