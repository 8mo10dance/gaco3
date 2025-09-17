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

        # AST パターンを定義
        # `(send nil? :hoge (int _))` は、以下のノード構造にマッチします。
        # - send: メソッド呼び出し
        # - nil?: レシーバーがない（レシーバーが nil）
        # - :hoge: メソッド名が `hoge`
        # - (int _): 最初の引数が int 型ノードであり、その値（_）は問わない
        #
        # `(send _ :hoge (int _))` とすると、レシーバーの有無を問わないパターンになります。
        def_node_matcher :hoge_with_int_arg?, '(send _ :hoge (int _))'

        # `hoge` の引数が float の場合も考慮
        def_node_matcher :hoge_with_float_arg?, '(send _ :hoge (float _))'

        def on_send(node)
          # 定義したパターンにマッチするかをチェック
          if hoge_with_int_arg?(node) || hoge_with_float_arg?(node)
            add_offense(node)
          end
        end
      end
    end
  end
end
