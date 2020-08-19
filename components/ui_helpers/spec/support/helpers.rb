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

  def construct_binding(*modules)
    construct_template(*modules).instance_eval { binding }
  end

  class StringRenderer < ActionView::Template::Handlers::Erubis
    include Helpers
    def with(*modules)
      Capybara::Node::Simple.new result(construct_binding(*modules))
    end
  end
end
