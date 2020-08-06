# frozen_string_literal: true

class PdfReport < Prawn::Document
  include Prawn::Measurements

  def initialize(options = { })
    options.merge!(:margin => [50, 70]) if options[:margin].nil?

    super(options)

    font "Times-Roman"
    font_size 12
  end

  def text(text, options = { })
    options.merge!({ :align => :justify }) unless options.key?(:align)

    super text, options
  end
end
