module Notifier
  class ReplaceTokenRenderer < Redcarpet::Render::HTML

    def initialize(*args)
      super
      @attributes = extensions[:attributes]
    end

    def preprocess(template)
      merge_data_attributes(template)
    end

    # Assumes document attribute tokens are in form: @attribute
    def merge_data_attributes(template)
      @attributes.each_pair { |token, value| template.gsub!("<% #{token} %>", value) }
      template
    end

  end
end
