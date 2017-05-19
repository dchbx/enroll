module UIHelpers
  module NavHelper
    def nav(options={})
      content_tag :ul, class: "nav nav-#{options[:type]} #{options[:class]}" do
        yield NavBuilder.new(options, self)
      end
    end

    class NavBuilder
      attr_accessor :template
      delegate :capture, :content_tag, :link_to, to: :template

      def initialize(options={}, template)
        @template = template || options
      end

      def pill(ref=nil, title=nil, options={}, &block)
        title ||= ref.to_s
        ref = title.parameterize.underscore.to_sym if title == ref
        content_tag :li, role: 'presentation', class: options[:active] ? 'active' : '' do
          if block_given?
            link_to "##{ref}", 'aria-controls' => ref, role: 'pill', 'data-toggle' => 'pill', &block
          else
            link_to title, "##{ref}", 'aria-controls' => ref, role: 'pill', 'data-toggle' => 'pill'
          end
        end
      end

      def tab(title=nil, options={}, &block)
        content_tag :li, role: 'presentation', class: options[:active] ? 'active' : '' do
          if block_given?
            link_to '#', &block
          else
            link_to title, '#'
          end
        end
      end
    end
  end
end
