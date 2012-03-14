require 'helper'

class Rails
  class Env
    def self.test?
      false
    end
  end

  def self.env
    Env
  end
end

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

ActiveRecord::Base.class_eval do
  silence do
    connection.create_table :people, :force => true do |t|
      t.column :name, :string
    end
  end
end

class Person < ActiveRecord::Base
  is_msfte_searchable(:columns => %w(name))
end

# The SQL generated is courtesy of the sqlite adapter, so the whitespace and
# quoting behavior are specific to it and may be brittle.
describe IsMsfteSearchable::ArelMixin do

  describe ".msfte_with_phrase" do
    it "exists" do
      Person.must_respond_to(:msfte_with_phrase)
    end

    it "returns a scope searching for the query as a phrase" do
      Person.msfte_with_phrase('foo bar').to_sql.must_equal(
        %{SELECT "people".* FROM "people"  WHERE (people.id IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(people,*,'"foo bar *"') AS KEY_TBL))}
      )
    end

    it "returns an empty scope when the query is blank" do
      Person.msfte_with_phrase('').to_sql.must_equal(
        %{SELECT "people".* FROM "people" }
      )
    end
  end

  describe ".msfte_with_any" do
    it "exists" do
      Person.must_respond_to(:msfte_with_any)
    end

    it "returns a scope searching for any of the query terms" do
      Person.msfte_with_any('foo bar').to_sql.must_equal(
        %{SELECT "people".* FROM "people"  WHERE (people.id IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(people,*,'"foo *" OR "bar *"') AS KEY_TBL))}
      )
    end

    it "returns an empty scope when the query is blank" do
      Person.msfte_with_any('').to_sql.must_equal(
        %{SELECT "people".* FROM "people" }
      )
    end
  end

  describe ".msfte_with_all" do
    it "exists" do
      Person.must_respond_to(:msfte_with_all)
    end

    it "returns a scope searching for all of the query terms" do
      Person.msfte_with_all('foo bar').to_sql.must_equal(
        %{SELECT "people".* FROM "people"  WHERE (people.id IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(people,*,'"foo *" AND "bar *"') AS KEY_TBL))}
      )
    end

    it "returns an empty scope when the query is blank" do
      Person.msfte_with_all('').to_sql.must_equal(
        %{SELECT "people".* FROM "people" }
      )
    end
  end

  describe ".msfte_with_booleans" do
    it "exists" do
      Person.must_respond_to(:msfte_with_booleans)
    end

    it "returns a scope searching for the query terms as given?" do
      Person.msfte_with_booleans('foo bar').to_sql.must_equal(
        %{SELECT "people".* FROM "people"  WHERE (people.id IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(people,*,'foo bar') AS KEY_TBL))}
      )
    end

    it "returns an empty scope when the query is blank" do
      Person.msfte_with_booleans('').to_sql.must_equal(
        %{SELECT "people".* FROM "people" }
      )
    end
  end

  describe "column methods" do

    describe ".msfte_name_with_any" do
      it "exists" do
        Person.must_respond_to(:msfte_name_with_any)
      end

      it "returns a scope searching for any of the query terms" do
        Person.msfte_name_with_any('foo bar').to_sql.must_equal(
          %{SELECT "people".* FROM "people"  WHERE (people.id IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(people,name,'"foo *" OR "bar *"') AS KEY_TBL))}
        )
      end

      it "returns an empty scope when the query is blank" do
        Person.msfte_name_with_any('').to_sql.must_equal(
          %{SELECT "people".* FROM "people" }
        )
      end

      it "returns a scope using a LIKE query when Rails.env.test?" do
        Rails.env.stubs(:test?).returns(true)
        Person.msfte_name_with_any('foo bar').to_sql.must_equal(
          %{SELECT "people".* FROM "people"  WHERE (people.name LIKE '%foo bar%')}
        )
      end
    end

    describe ".msfte_name_with_all" do
      it "exists" do
        Person.must_respond_to(:msfte_name_with_all)
      end

      it "returns a scope searching for all of the query terms" do
        Person.msfte_name_with_all('foo bar').to_sql.must_equal(
          %{SELECT "people".* FROM "people"  WHERE (people.id IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(people,name,'"foo *" AND "bar *"') AS KEY_TBL))}
        )
      end

      it "returns an empty scope when the query is blank" do
        Person.msfte_name_with_all('').to_sql.must_equal(
          %{SELECT "people".* FROM "people" }
        )
      end

      it "returns a scope using a LIKE query when Rails.env.test?" do
        Rails.env.stubs(:test?).returns(true)
        Person.msfte_name_with_all('foo bar').to_sql.must_equal(
          %{SELECT "people".* FROM "people"  WHERE (people.name LIKE '%foo bar%')}
        )
      end
    end

    describe ".msfte_name_with_booleans" do
      it "exists" do
        Person.must_respond_to(:msfte_name_with_booleans)
      end

      it "returns a scope searching for the query terms as given?" do
        Person.msfte_name_with_booleans('foo bar').to_sql.must_equal(
          %{SELECT "people".* FROM "people"  WHERE (people.id IN (SELECT [KEY_TBL].[KEY] FROM CONTAINSTABLE(people,name,'foo bar') AS KEY_TBL))}
        )
      end

      it "returns an empty scope when the query is blank" do
        Person.msfte_name_with_booleans('').to_sql.must_equal(
          %{SELECT "people".* FROM "people" }
        )
      end

      it "returns a scope using a LIKE query when Rails.env.test?" do
        Rails.env.stubs(:test?).returns(true)
        Person.msfte_name_with_booleans('foo bar').to_sql.must_equal(
          %{SELECT "people".* FROM "people"  WHERE (people.name LIKE '%foo bar%')}
        )
      end
    end
  end

end
