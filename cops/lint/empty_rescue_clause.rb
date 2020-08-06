# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      class EmptyRescueClause < Cop
        include RescueNode

        def_node_matcher :rescue_with_empty_body?, <<-PATTERN
          (resbody _ _ {nil? (nil) (array) (hash)})
        PATTERN

        def on_resbody(node)
          rescue_with_empty_body?(node) do |_error|
            add_offense(node, location: node.source_range, message: 'Avoid empty `rescue` bodies.')
          end
        end
      end
    end
  end
end
