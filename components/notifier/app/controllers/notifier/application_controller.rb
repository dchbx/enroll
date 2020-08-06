# frozen_string_literal: true

module Notifier
  class ApplicationController < ActionController::Base
    include Pundit
    layout "notifier/single_column"
  end
end
