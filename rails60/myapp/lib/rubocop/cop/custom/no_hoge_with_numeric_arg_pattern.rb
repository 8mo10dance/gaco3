# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      class NoHogeWithNumericArgPattern < Base
        extend AutoCorrector

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

          add_offense(node) do |corrector|
            autocorrect_value_hash(corrector, node)
          end
        end

        private

        def autocorrect_value_hash(corrector, node)
          first_arg = node.arguments.first
          target_node = first_arg.pairs.find { |pair_node| value_int_pair?(pair_node) }
          target_pair_arr = target_node.value.pairs.map do |pair|
            [pair.key.value, int_to_boolean(pair.value.value)]
          end
          value_hash_str = target_pair_arr.map { |k, v| "#{k}: #{v}" }.join(', ')

          new_code = <<~RUBY.chomp
            value: { #{value_hash_str} }
          RUBY
          corrector.replace(target_node, new_code)
        end

        def int_to_boolean(val)
          val == 1
        end
      end
    end
  end
end
