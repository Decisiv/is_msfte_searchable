require 'helper'

describe IsMsfteSearchable::ActiveRecordExtension do
  it "extends ActiveRecord::Base with an is_msfte_searchable class method" do
    ActiveRecord::Base.must_respond_to(:is_msfte_searchable)
  end

  it "extends ActiveRecord::Base with an msfte_pending_changes? method" do
    ActiveRecord::Base.must_respond_to(:msfte_pending_changes?)
  end

  class FakeActiveRecord
    def self.table_name
      'people'
    end

    def self.column_names
      %w(id name)
    end

    def self.primary_key
      'id'
    end

    include IsMsfteSearchable::ActiveRecordExtension
  end

  describe ".is_msfte_searchable" do
    let(:model) do
      Class.new(FakeActiveRecord)
    end

    describe "adds msfte_table_name class method" do
      it "that exists" do
        model.is_msfte_searchable
        model.must_respond_to(:msfte_table_name)
      end

      it "defaults to the model's table_name" do
        model.is_msfte_searchable
        model.msfte_table_name.must_equal 'people'
      end

      it "is overridden by the :table_name option" do
        model.is_msfte_searchable(:table_name => 'persons')
        model.msfte_table_name.must_equal 'persons'
      end

      it "and an accessor method" do
        model.is_msfte_searchable
        model.msfte_table_name = 'persons'
        model.msfte_table_name.must_equal 'persons'
      end
    end

    describe "adds msfte_columns class method" do
      it "that exists" do
        model.is_msfte_searchable
        model.must_respond_to(:msfte_columns)
      end

      it "defaults to the model's column_names" do
        model.is_msfte_searchable
        model.msfte_columns.must_equal %w(id name)
      end

      it "is overriden by the :columns option" do
        model.is_msfte_searchable(:columns => [:first_name, :last_name])
        model.msfte_columns.must_equal %w(first_name last_name)
      end

      it "and an accessor method" do
        model.is_msfte_searchable
        model.msfte_columns = %w(first_name last_name)
        model.msfte_columns.must_equal %w(first_name last_name)
      end
    end

    describe "adds msfte_catalog class method" do
      it "that exists" do
        model.is_msfte_searchable
        model.must_respond_to(:msfte_catalog)
      end

      it "defaults to a value derived from the msfte_table_name" do
        model.is_msfte_searchable
        model.msfte_catalog.must_equal "people_fti"
      end

      it "is overridden by the :catalog option" do
        model.is_msfte_searchable(:catalog => 'persons_fti')
        model.msfte_catalog.must_equal "persons_fti"
      end

      it "and an accessor method" do
        model.is_msfte_searchable
        model.msfte_catalog = 'persons_fti'
        model.msfte_catalog.must_equal "persons_fti"
      end
    end

    describe "adds msfte_unique_key_column class method" do
      it "that exists" do
        model.is_msfte_searchable
        model.must_respond_to(:msfte_unique_key_column)
      end

      it "defaults to the model's primary_key" do
        model.is_msfte_searchable
        model.msfte_unique_key_column.must_equal 'id'
      end

      it "is overridden by the :unique_key_column option" do
        model.is_msfte_searchable(:unique_key_column => 'pkey')
        model.msfte_unique_key_column.must_equal 'pkey'
      end

      it "and an accessor method" do
        model.is_msfte_searchable
        model.msfte_unique_key_column = 'pkey'
        model.msfte_unique_key_column.must_equal 'pkey'
      end
    end

    describe "adds msfte_unique_key_index class method" do
      it "that exists" do
        model.is_msfte_searchable
        model.must_respond_to(:msfte_unique_key_index)
      end

      it "defaults to a value derived from the msfte_unique_key_column" do
        model.is_msfte_searchable
        model.msfte_unique_key_index.must_equal('id_idx')
      end

      it "is overridden by the :unique_key_index option" do
        model.is_msfte_searchable(:unique_key_index => 'my_index')
        model.msfte_unique_key_index.must_equal('my_index')
      end

      it "and an accessor method" do
        model.is_msfte_searchable
        model.msfte_unique_key_index = 'my_index'
        model.msfte_unique_key_index.must_equal('my_index')
      end
    end

    describe "adds msfte_change_tracking class method" do
      it "that exists" do
        model.is_msfte_searchable
        model.must_respond_to(:msfte_change_tracking)
      end

      it "defaults to true" do
        model.is_msfte_searchable
        model.msfte_change_tracking.must_equal true
      end

      it "is overridden by the :change_tracking option" do
        model.is_msfte_searchable(:change_tracking => false)
        model.msfte_change_tracking.must_equal false
      end

      it "and an accessor method" do
        model.is_msfte_searchable
        model.msfte_change_tracking = false
        model.msfte_change_tracking.must_equal false
      end
    end

    describe "adds msfte_update_index class method" do
      it "that exists" do
        model.is_msfte_searchable
        model.must_respond_to(:msfte_update_index)
      end

      it "defaults to true" do
        model.is_msfte_searchable
        model.msfte_update_index.must_equal true
      end

      it "is overridden by the :update_index option" do
        model.is_msfte_searchable(:update_index => false)
        model.msfte_update_index.must_equal false
      end

      it "and an accessor method" do
        model.is_msfte_searchable
        model.msfte_update_index = false
        model.msfte_update_index.must_equal false
      end
    end

  end
end
