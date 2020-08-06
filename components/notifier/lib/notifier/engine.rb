# frozen_string_literal: true

# require 'ckeditor'

require 'mongoid'
require 'virtus'
require "aasm"
require "wkhtmltopdf-binary-edge"
require "wicked_pdf"
require 'ckeditor'
require "redcarpet"
require "config"
require "money-rails"

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
      g.fixture_replacement :Factory_bot, :dir => 'spec/factories'
      g.assets true
      g.helper true
    end
  end
end
