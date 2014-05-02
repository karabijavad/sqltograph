require 'spec_helper'

describe Sqltograph do
  it "creates test tables etc" do
    ActiveRecord::Base.connection.execute "CREATE TABLE persons (id serial PRIMARY KEY, name VARCHAR(100))"
    ActiveRecord::Base.connection.execute "CREATE TABLE homes (id serial PRIMARY KEY, address VARCHAR(100), owner INT REFERENCES persons(id))"

    ActiveRecord::Base.connection.execute "INSERT INTO persons (name) VALUES ('javad')"
    ActiveRecord::Base.connection.execute "INSERT INTO persons (name) VALUES ('eric')"

    ActiveRecord::Base.connection.execute "INSERT INTO homes (address, owner) VALUES ('1223 berkeley lake lane, houston, tx', 1)"
    ActiveRecord::Base.connection.execute "INSERT INTO homes (address, owner) VALUES ('2206 n milwaukeee, chicago, il', 2)"

    def create_activerecord_class table_name
      Class.new(ActiveRecord::Base) do
         self.table_name = table_name
      end
    end

    models = []
    ActiveRecord::Base.connection.tables.each do |table|
      models << create_activerecord_class(table)
    end

    models.each do |model|
      model.all.each do |object|
        binding.pry
      end
    end
  end
end
