# frozen_string_literal: true

module RuboCop
  module Cop
    module CustomCops
      class BabySqueelWhereHas < Base
        MSG = 'baby_squeelの`where.has`ではなく、生クエリを使ってください'

        def_node_search :where_has?, <<~PATTERN
          (block
            (send
              (send _ :where)
              :has)
            ...)
        PATTERN

        def on_block(node)
          return unless where_has?(node)

          add_offense(node)
        end
      end
    end
  end
end
