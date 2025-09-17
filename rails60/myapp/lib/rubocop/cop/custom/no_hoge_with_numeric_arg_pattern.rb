# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      # この Cop は、`hoge` メソッドの引数が数値である場合に警告します。
      #
      # @example
      #   # bad
      #   hoge(123)
      #   hoge(4.56)
      #
      #   # good
      #   hoge('string')
      #   hoge(variable)
      class NoHogeWithNumericArgPattern < Base
        MSG = 'Do not call `hoge` with a numeric argument.'.freeze

        def_node_matcher :hoge_with_value_hash?, <<~PATTERN
          (send _ :hoge
            (hash
              (pair
                (sym :value)
                (int _))
              ...))
        PATTERN

        def on_send(node)
          # 定義したパターンにマッチするかをチェック
          if hoge_with_value_hash?(node)
            add_offense(node)
          end
        end
      end
    end
  end
end
