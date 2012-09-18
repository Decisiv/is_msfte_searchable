require 'active_support/concern'
require 'active_record'
require 'is_msfte_searchable/active_record_extension'
require 'is_msfte_searchable/active_record_mixin'
require 'is_msfte_searchable/arel_mixin'
require 'is_msfte_searchable/no_full_text_index_error'
require 'is_msfte_searchable/version'

ActiveRecord::Base.send :include, IsMsfteSearchable::ActiveRecordExtension
