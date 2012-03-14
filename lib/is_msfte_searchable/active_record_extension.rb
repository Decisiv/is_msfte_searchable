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
end
