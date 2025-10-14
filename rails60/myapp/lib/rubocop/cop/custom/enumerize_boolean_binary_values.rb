module RuboCop
  module Cop
    module Custom
      class EnumerizeBooleanBinaryValues < Base
        MSG = 'Boolean 型カラムの enumerize で 0,1 を使う箇所は Rails 6.1 バージョンアップにより動かなくなります'.freeze

        def_node_matcher :enumerize_with_hash?, <<~PATTERN
          (send nil? :enumerize (sym $_) (hash (pair (sym :in) (hash $...))))
        PATTERN

        def on_new_investigation
          load_rails
        end

        def on_send(node)
          enumerize_with_hash?(node) do |attr_name, hash_pairs|
            return unless boolean_column?(attr_name)
            return unless binary_values?(hash_pairs)

            add_offense(node)
          end
        end

        private

        def load_rails
          require_relative '../../../../config/environment'
        end

        def boolean_column?(attr_name)
          return false unless defined?(ActiveRecord::Base)

          model_class = infer_model_class
          return false unless model_class
          return false unless model_class < ActiveRecord::Base

          column = model_class.columns.find { |col| col.name == attr_name.to_s }
          column&.type == :boolean
        end

        def binary_values?(hash_pairs)
          values = hash_pairs.filter_map do |pair|
            pair.children[1].int_type? ? pair.children[1].value : nil
          end

          values.include?(0) && values.include?(1)
        end

        def infer_model_class
          file_path = processed_source.file_path
          relative_path = file_path.sub(%r{.*?/app/models/}, '').delete_suffix('.rb')
          class_name = relative_path.camelize
          class_name.safe_constantize
        end
      end
    end
  end
end
