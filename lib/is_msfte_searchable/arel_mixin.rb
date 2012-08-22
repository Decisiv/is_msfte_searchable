module IsMsfteSearchable
  module ArelMixin
    extend ActiveSupport::Concern

    included do
      class_eval do
        scope :msfte_with_phrase, lambda { |query|
          return {} if query.blank?
          msfte_contains(msfte_search_string(query))
        }

        scope :msfte_with_any, lambda { |query|
          return {} if query.blank?
          msfte_contains(msfte_search_string(query, 'OR'))
        }

        scope :msfte_with_all, lambda { |query|
          return {} if query.blank?
          msfte_contains(msfte_search_string(query, 'AND'))
        }

        scope :msfte_with_booleans, lambda { |query|
          return {} if query.blank?
          msfte_contains(query, :quote => true)
        }

        msfte_columns.each do |c|
          scope "msfte_#{c}_with_any".to_sym, lambda { |query|
            return {} if query.blank?
            return msfte_like_bailout(c, query) unless msfte_column_indexed?(c)
            msfte_contains(msfte_search_string(query, 'OR'), :column => c)
          }

          scope "msfte_#{c}_with_all".to_sym, lambda { |query|
            return {} if query.blank?
            return msfte_like_bailout(c, query) unless msfte_column_indexed?(c)
            msfte_contains(msfte_search_string(query, 'AND'), :column => c)
          }

          scope "msfte_#{c}_with_booleans".to_sym, lambda { |query|
            return {} if query.blank?
            return msfte_like_bailout(c, query) unless msfte_column_indexed?(c)
            msfte_contains(query, :column => c, :quote => true)
          }
        end
      end
    end

    module ClassMethods
      private

      def msfte_like_bailout(column, query)
        { :conditions => "#{table_name}.#{column} LIKE '%#{msfte_quote(query)}%'" }
      end

      def msfte_contains(query, options = {})
        column = options.fetch(:column, '*')
        quote = options.fetch(:quote, false)
        query_literal = quote ? '?' : query
        condition = "#{table_name}.#{primary_key} IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(#{msfte_table_name},#{column},#{query_literal}) AS KEY_TBL)"
        conditions = quote ? [condition, query] : condition
        { :conditions => conditions }
      end
    end
  end
end
