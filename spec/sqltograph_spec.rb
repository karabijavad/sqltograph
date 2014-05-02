require 'spec_helper'

describe Sqltograph do
  it "creates test tables etc" do
    [
      "CREATE TABLE persons (id serial PRIMARY KEY, name VARCHAR(100), age INT)",
      "CREATE TABLE homes (id serial PRIMARY KEY, address VARCHAR(100), owner INT REFERENCES persons(id))",
      "INSERT INTO persons (name, age) VALUES ('javad', 25)",
      "INSERT INTO persons (name, age) VALUES ('shaaheen', 24)",
      "INSERT INTO homes (address, owner) VALUES ('1223 berkeley lake lane, houston, tx', 1)",
      "INSERT INTO homes (address, owner) VALUES ('2206 n milwaukeee, chicago, il', 1)"
    ].each { |query| ActiveRecord::Base.connection.execute query }

    models = ActiveRecord::Base.connection.tables.map do |table_name|
      Class.new(ActiveRecord::Base) { self.table_name = table_name }
    end

    `rm -rf /Users/karabijavad/Downloads/neo4j-community-2.0.3/data/graph.db/`

    Cadet::Session.open "/Users/karabijavad/Downloads/neo4j-community-2.0.3/data/graph.db/" do |neo_session|
      transaction do
        models.each do |model|
          models_pk = ActiveRecord::Base.connection.execute("
            SELECT
              pg_attribute.attname,
              format_type(pg_attribute.atttypid, pg_attribute.atttypmod)
            FROM pg_index, pg_class, pg_attribute
            WHERE
              pg_class.oid = '#{model.table_name}'::regclass AND
              indrelid = pg_class.oid AND
              pg_attribute.attrelid = pg_class.oid AND
              pg_attribute.attnum = any(pg_index.indkey)
              AND indisprimary
          ").first['attname']
          models_fks = ActiveRecord::Base.connection.execute("
            SELECT
                tc.constraint_name, tc.table_name, kcu.column_name,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name
            FROM
                information_schema.table_constraints AS tc
                JOIN information_schema.key_column_usage AS kcu
                  ON tc.constraint_name = kcu.constraint_name
                JOIN information_schema.constraint_column_usage AS ccu
                  ON ccu.constraint_name = tc.constraint_name
            WHERE constraint_type = 'FOREIGN KEY' AND tc.table_name='#{model.table_name}';
          ")

          model.all.each do |ar_object|
            neo4j_node = neo_session.get_node model.table_name, models_pk, ar_object[models_pk]

            ar_object.attributes.each do |attr|
              neo4j_node[attr[0]] = attr[1]
            end
            models_fks.each do |fk|
              other = get_node(fk['foreign_table_name'], fk['foreign_column_name'], ar_object[fk['column_name']])
              neo4j_node.send("#{fk['column_name']}_to", other)
            end
          end
        end
      end

      transaction do
        neo_session.get_node("persons", "name", "javad")[:age].should == 25
        neo_session.get_node("persons", "name", "shaaheen")[:age].should == 24

        neo_session.find_node("homes", "address", "1223 berkeley lake lane, houston, tx")[:owner].should == 1
        neo_session.find_node("homes", "address", "1223 berkeley lake lane, houston, tx")[:owner].should == 1
      end
    end
  end
end
