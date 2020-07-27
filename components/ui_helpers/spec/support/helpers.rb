require 'capybara'
module Helpers
  def render(string)
    StringRenderer.new(string)
  end

  def construct_template(*modules)
    object = Object.new
    modules.each { |name| object.extend name }

    object
      .extend(ActionView::Helpers)
      .extend(ActionView::Helpers::UrlHelper)
      .extend(ActionView::Context)
  end

  class StringRenderer < ActionView::Template::Handlers::ERB::Erubi
    include Helpers

    def with(*modules)
      Capybara::Node::Simple.new evaluate(construct_template(*modules))
    end
  end
end
