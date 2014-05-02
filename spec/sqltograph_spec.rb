require 'spec_helper'

describe Sqltograph do
  it "creates test tables etc" do
    ActiveRecord::Base.connection.execute "CREATE TABLE persons (id serial PRIMARY KEY, name VARCHAR(100), age INT)"
    ActiveRecord::Base.connection.execute "CREATE TABLE homes (id serial PRIMARY KEY, address VARCHAR(100), owner INT REFERENCES persons(id))"

    ActiveRecord::Base.connection.execute "INSERT INTO persons (name, age) VALUES ('javad', 25)"
    ActiveRecord::Base.connection.execute "INSERT INTO persons (name, age) VALUES ('shaaheen', 24)"

    ActiveRecord::Base.connection.execute "INSERT INTO homes (address, owner) VALUES ('1223 berkeley lake lane, houston, tx', 1)"
    ActiveRecord::Base.connection.execute "INSERT INTO homes (address, owner) VALUES ('2206 n milwaukeee, chicago, il', 2)"

    models = ActiveRecord::Base.connection.tables.map do |table_name|
      Class.new(ActiveRecord::Base) { self.table_name = table_name }
    end

    Cadet::Session.open do |neo_session|
      transaction do
        models.each do |model|
          model.all.each do |ar_object|
            neo4j_node = neo_session.get_node model.table_name, :id, ar_object.id
            ar_object.attributes.each do |attr|
              neo4j_node[attr[0]] = attr[1]
            end
          end
        end
      end

      transaction do
        neo_session.get_node("persons", "name", "javad")[:age].should == 25
        neo_session.get_node("persons", "name", "shaaheen")[:age].should == 24
      end
    end
  end
end
