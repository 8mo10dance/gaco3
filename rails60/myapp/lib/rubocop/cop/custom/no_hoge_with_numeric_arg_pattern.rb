# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      class NoHogeWithNumericArgPattern < Base
        MSG = 'Do not call `hoge` with a numeric argument.'.freeze

        def_node_matcher :hoge_with_value_hash?, <<~PATTERN
          (send _ :hoge
            (hash ...))
        PATTERN

        def_node_matcher :value_int_pair?, <<~PATTERN
          (pair
            (sym :value)
            (hash
              (pair (sym _) (int {0 1}))
              (pair (sym _) (int {0 1}))))
        PATTERN

        def on_send(node)
          return unless hoge_with_value_hash?(node)

          first_arg = node.arguments.first
          return unless first_arg.pairs.any? { |pair_node| value_int_pair?(pair_node) }

          add_offense(node)
        end
      end
    end
  end
end
