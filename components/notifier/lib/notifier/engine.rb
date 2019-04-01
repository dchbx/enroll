# require 'ckeditor'

require "wkhtmltopdf-binary-edge"
require "wicked_pdf"

module Notifier
  class Engine < ::Rails::Engine
    isolate_namespace Notifier

    # config.to_prepare do
    #   ApplicationController.helper(ActionView::Helpers::ApplicationHelper)
    # end

    config.generators do |g|
      g.orm :mongoid 
      g.template_engine :slim
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets true
      g.helper true 
    end
  end
end