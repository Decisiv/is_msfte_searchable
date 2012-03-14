require 'helper'

describe IsMsfteSearchable::ActiveRecordMixin do
  class FakeConnection
    def execute(command)
    end

    def quote_string(value)
      value
    end
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

    def self.connection
      @connection ||= FakeConnection.new
    end

    include IsMsfteSearchable::ActiveRecordExtension
  end

  let(:model) do
    model = Class.new(FakeActiveRecord)
    model.is_msfte_searchable
    model
  end

  it "shouldn't leak from model to model" do
    model1 = Class.new(FakeActiveRecord)
    model2 = Class.new(FakeActiveRecord)
    model1.is_msfte_searchable
    model2.is_msfte_searchable
    model1.msfte_change_tracking.must_equal true
    model2.msfte_change_tracking.must_equal true
    model1.msfte_change_tracking = false
    model1.msfte_change_tracking.must_equal false
    model2.msfte_change_tracking.must_equal true
  end

  describe "adds msfte_setup class method" do
    it "that exists" do
      model.must_respond_to(:msfte_setup)
    end

    it "that executes setup commands on the model's database connection" do
      setup = sequence('setup')
      connection = mock('connection') do
        [
          "sp_fulltext_catalog 'people_fti', 'create'",
          "sp_fulltext_table 'dbo.people', 'create', 'people_fti', 'id_idx'",
          "sp_fulltext_column 'people', 'id', 'add'",
          "sp_fulltext_column 'people', 'name', 'add'",
          "sp_fulltext_table 'dbo.people', 'start_change_tracking'",
          "sp_fulltext_table 'dbo.people', 'start_background_updateindex'"
        ].each do |command|
          expects(:execute).with(command).in_sequence(setup)
        end
      end
      model.stubs(:connection).returns(connection)
      model.msfte_setup
    end
  end

  describe "adds msfte_teardown class method" do
    it "that exists" do
      model.must_respond_to(:msfte_teardown)
    end

    it "executes teardown commands on the model's database connection" do
      teardown = sequence(:teardown)
      connection = mock('connection') do
        [
          "sp_fulltext_table 'dbo.people', 'drop'",
          "sp_fulltext_catalog 'people_fti', 'drop'"
        ].each do |command|
          expects(:execute).with(command).in_sequence(teardown)
        end
      end
      model.stubs(:connection).returns(connection)
      model.msfte_teardown
    end
  end

  describe "adds msfte_reset! class method" do
    it "that exists" do
      model.must_respond_to(:msfte_reset!)
    end

    it "calls msfte_teardown, then msfte_setup" do
      catalog = states('catalog').starts_as('up')
      model.expects(:msfte_teardown).then(catalog.is('down'))
      model.expects(:msfte_setup).when(catalog.is('down')).then(catalog.is('up'))
      model.msfte_reset!
    end

    it "yields the given block after msfte_teardown before msfte_setup" do
      catalog = states('catalog').starts_as('up')
      model.expects(:msfte_teardown).then(catalog.is('down'))
      model.expects(:call_the_block!).when(catalog.is('down'))
      model.expects(:msfte_setup).when(catalog.is('down')).then(catalog.is('up'))
      model.msfte_reset! do
        model.call_the_block!
      end
    end
  end

  describe "adds msfte_catalog_rebuild class method" do
    it "that exists" do
      model.must_respond_to(:msfte_catalog_rebuild)
    end

    it "executes rebuild commands on the model's database connection" do
      connection = mock('connection') do
        command = "sp_fulltext_catalog 'people_fti', 'rebuild'"
        expects(:execute).with(command)
      end
      model.stubs(:connection).returns(connection)
      model.msfte_catalog_rebuild
    end
  end

  describe "adds msfte_quote class method" do
    it "that exists" do
      model.must_respond_to(:msfte_quote)
    end

    it "delegates to the model's database connection" do
      connection = mock('connection') do
        expects('quote_string').with('unquoted').returns('quoted')
      end
      model.stubs(:connection).returns(connection)
      model.msfte_quote('unquoted').must_equal 'quoted'
    end
  end

  describe "adds msfte_search_string method" do
    it "that exists" do
      model.must_respond_to(:msfte_search_string)
    end

    it "adds a wildcard to and quotes the query" do
      model.msfte_search_string('query').must_equal "'\"query *\"'"
    end

    it "joins the query with the given boolean operator" do
      model.msfte_search_string('term1 term2 ', 'OR').must_equal "'\"term1 *\" OR \"term2 *\"'"
    end
  end

end
