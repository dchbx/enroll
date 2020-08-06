# frozen_string_literal: true

unless defined?($LOADING_CUCUMBER_ENV) && $LOADING_CUCUMBER_ENV
  ENV["RAILS_ENV"] ||= 'test'
  require "email_spec"
  require 'email_spec/cucumber'
  require 'rspec/expectations'
  require 'capybara/cucumber'
  require 'capybara-screenshot/cucumber'
  require 'cucumber/rspec/doubles'

  require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
  Dir[File.expand_path(Rails.root.to_s + "/lib/test/**/*.rb")].each { |f| load f }
  require "rspec/rails"
  require_relative '../../spec/ivl_helper'
end
