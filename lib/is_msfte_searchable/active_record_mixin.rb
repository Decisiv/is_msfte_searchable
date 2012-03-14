module IsMsfteSearchable
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
end
