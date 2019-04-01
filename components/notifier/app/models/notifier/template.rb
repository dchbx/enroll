module Notifier
  class Template
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :notice_kind

    field :markup_kind, type: String, default: "markdown"
    field :raw_body, type: String
    field :raw_header, type: String
    field :raw_footer, type: String
    field :template_key, type: String
    field :data_elements, type: Array, default: []

    validates_presence_of :raw_body

    def to_s
      [raw_header, raw_body, raw_footer].join('\n\n')
    end

  end
end
