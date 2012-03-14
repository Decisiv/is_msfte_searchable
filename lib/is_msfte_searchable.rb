require 'active_support/concern'
require 'active_record'

module IsMsfteSearchable
  module ActiveRecordExtension
    extend ActiveSupport::Concern

    module ClassMethods
      def is_msfte_searchable(options={})
        options.reverse_merge! :change_tracking => true, :update_index => true
        cattr_accessor :msfte_table_name, :msfte_columns, :msfte_catalog, :msfte_unique_key_column, :msfte_unique_key_index, :msfte_change_tracking, :msfte_update_index
        self.msfte_table_name         = options[:table_name] ? options[:table_name].to_s : table_name
        self.msfte_columns            = options[:columns] ? options[:columns].map(&:to_s) : column_names
        self.msfte_catalog            = options[:catalog] ? options[:catalog].to_s : "#{msfte_table_name}_fti"
        self.msfte_unique_key_column  = options[:unique_key_column] ? options[:unique_key_column].to_s : primary_key
        self.msfte_unique_key_index   = options[:unique_key_index] ? options[:unique_key_index].to_s : "#{msfte_unique_key_column}_idx"
        self.msfte_change_tracking    = options[:change_tracking]
        self.msfte_update_index       = options[:update_index]
        include IsMsfteSearchable::ActiveRecordMixin
        include IsMsfteSearchable::ArelMixin
      end
    end
  end

  module ActiveRecordMixin
    extend ActiveSupport::Concern

    module ClassMethods
      def msfte_setup
        connection.execute %|sp_fulltext_catalog '#{msfte_catalog}', 'create'|
        connection.execute %|sp_fulltext_table 'dbo.#{msfte_table_name}', 'create', '#{msfte_catalog}', '#{msfte_unique_key_index}'|
        msfte_columns.each { |col| connection.execute(%|sp_fulltext_column '#{msfte_table_name}', '#{col}', 'add'|) }
        connection.execute %|sp_fulltext_table 'dbo.#{msfte_table_name}', 'start_change_tracking'| if msfte_change_tracking
        connection.execute %|sp_fulltext_table 'dbo.#{msfte_table_name}', 'start_background_updateindex'| if msfte_update_index
      end

      def msfte_teardown
        connection.execute %|sp_fulltext_table 'dbo.#{msfte_table_name}', 'drop'| rescue nil
        connection.execute %|sp_fulltext_catalog '#{msfte_catalog}', 'drop'| rescue nil
      end

      def msfte_reset!
        msfte_teardown
        yield if block_given?
        msfte_setup
      end

      def msfte_catalog_rebuild
        connection.execute %|sp_fulltext_catalog '#{msfte_catalog}', 'rebuild'|
      end

      def msfte_quote(string)
        connection.quote_string(string)
      end

      def msfte_search_string(query, boolean=nil)
        if boolean
          # sql2k won't treat punctuation as valid search terms, so strip them out until we upgrade to 2k5+
          termed_query = query.gsub(/[^\w\d\s]+/, '').split(/\s+/).map{ |term| %|"#{term} *"| }.join(" #{boolean} ").strip
        else
          termed_query = %|"#{query} *"|
        end
        %|'#{msfte_quote(termed_query)}'|
      end
    end

  end

  module ArelMixin
    extend ActiveSupport::Concern

    included do
      class_eval do
        scope :msfte_with_phrase, lambda { |query|
          return {} if query.blank?
          { :conditions => "#{table_name}.#{primary_key} IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(#{msfte_table_name},*,#{msfte_search_string(query)}) AS KEY_TBL)" }
        }

        scope :msfte_with_any, lambda { |query|
          return {} if query.blank?
          { :conditions => "#{table_name}.#{primary_key} IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(#{msfte_table_name},*,#{msfte_search_string(query,'OR')}) AS KEY_TBL)" }
        }

        scope :msfte_with_all, lambda { |query|
          return {} if query.blank?
          { :conditions => "#{table_name}.#{primary_key} IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(#{msfte_table_name},*,#{msfte_search_string(query,'AND')}) AS KEY_TBL)" }
        }

        scope :msfte_with_booleans, lambda { |query|
          return {} if query.blank?
          { :conditions => ["#{table_name}.#{primary_key} IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(#{msfte_table_name},*,?) AS KEY_TBL)",query] }
        }

        msfte_columns.each do |c|
          scope "msfte_#{c}_with_any".to_sym, lambda { |query|
            return {} if query.blank?
            return msfte_like_bailout(c,query) if Rails.env.test?
            { :conditions => "#{table_name}.#{primary_key} IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(#{msfte_table_name},#{c},#{msfte_search_string(query,'OR')}) AS KEY_TBL)" }
          }

          scope "msfte_#{c}_with_all".to_sym, lambda { |query|
            return {} if query.blank?
            return msfte_like_bailout(c,query) if Rails.env.test?
            { :conditions => "#{table_name}.#{primary_key} IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(#{msfte_table_name},#{c},#{msfte_search_string(query,'AND')}) AS KEY_TBL)" }
          }

          scope "msfte_#{c}_with_booleans".to_sym, lambda { |query|
            return {} if query.blank?
            { :conditions => ["#{table_name}.#{primary_key} IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(#{msfte_table_name},*,?) AS KEY_TBL)",query] }
          }
        end
      end
    end

    module ClassMethods
      private

      def msfte_like_bailout(column, query)
        { :conditions => "#{table_name}.#{column} LIKE '%#{msfte_quote(query)}%'" }
      end
    end
  end
end

ActiveRecord::Base.send :include, IsMsfteSearchable::ActiveRecordExtension
