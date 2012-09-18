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

      def msfte_column_indexed?(column)
        # Any column in this table full-text indexed?
        sql_statement =
          <<-stmt
            select count(*)
            from sys.fulltext_index_columns fic
            inner join sys.columns c
              on c.[object_id] = fic.[object_id]
              and c.[column_id] = fic.[column_id]
            where OBJECT_ID('#{table_name}') = fic.[object_id]
          stmt

        # Search for an actual column name if given.
        sql_statement << " and name = '#{column}'" unless column == '*'

        value = connection.select_value(sql_statement)
        value.to_i == 1
      end

      # Query the object properties of the current table.
      # TableFulltextPendingChanges returns the number of pending changes.
      # See: http://technet.microsoft.com/en-us/library/ms188390.aspx
      def msfte_pending_changes?
        sql_statement =
          %|select cast(OBJECTPROPERTYEX(OBJECT_ID('#{table_name}'), 'TableFulltextPendingChanges') as varchar(10))|
        value = connection.select_value(sql_statement)
        value.to_i != 0
      end
    end
  end
end
