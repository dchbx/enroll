module UIHelpers
  module TabHelper
    def tab_content(options={})
      content_tag :div, class: "tab-content #{options[:class]}" do
        yield TabBuilder.new(options, self)
      end
    end

    class TabBuilder
      attr_accessor :template
      delegate :capture, :content_tag, :link_to, to: :template

      def initialize(options={}, template)
        @template = template || options
      end

      def tab(id, options={}, &block)
        content_tag :div, id: id, role: 'tabpanel', class: "tab-pane #{options[:active] ? 'active' : ''}" do
          capture &block
        end
      end
    end
  end
end
