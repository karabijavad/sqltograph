require "bundler/gem_tasks"
require 'bundler/setup'
Bundler.setup

require 'sqltograph'
require 'active_record'
require 'cadet'
require 'dotenv'

Dotenv.load

current_model = ""
current_model_id = 0

task :sqltograph do
  ActiveRecord::Base.establish_connection ENV['DATABASE_URL']
  models = ActiveRecord::Base.connection.tables.map do |table_name|
    Class.new(ActiveRecord::Base) { self.table_name = table_name }
  end

  `rm -rf /Users/karabijavad/Downloads/neo4j-community-2.0.3/data/graph.db/`

  Cadet::BatchInserter::Session.open "/Users/karabijavad/Downloads/neo4j-community-2.0.3/data/graph.db/" do |neo_session|
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
          p [model.table_name, ar_object[models_pk]] if Time.now.to_i % 100 == 0
          neo4j_node = get_node model.table_name, models_pk, ar_object[models_pk]

          ar_object.attributes.each do |attr|
              if attr[1].is_a?(Date) or attr[1].is_a?(DateTime) or attr[1].is_a?(Time)
                attr[1] = attr[1].to_i
              end
              neo4j_node[attr[0]] = attr[1] if attr[1]
          end
          models_fks.each do |fk|
            other = get_node(fk['foreign_table_name'], fk['foreign_column_name'], ar_object[fk['column_name']])
            neo4j_node.send("#{fk['column_name']}_to", other)
          end
        end
      end
    end
  end
end
