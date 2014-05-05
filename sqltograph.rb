require 'active_record'
require 'cadet'

current_model = ""
current_object_id = 0

Thread.new do
  while true do
    puts "#{current_model} #{current_object_id}"
    sleep 1
  end
end

ActiveRecord::Base.establish_connection ARGV[0]

models = ActiveRecord::Base.connection.tables.map do |table_name|
  Class.new(ActiveRecord::Base) { self.table_name = table_name }
end

`rm -rf #{ARGV[1]}`

Cadet::BatchInserter::Session.open ARGV[1] do |neo_session|
    models.each do |model|
      current_model = model.table_name
      puts current_model
      query = "
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
      "
      result = ActiveRecord::Base.connection.execute query
      row = result.first
      next unless row
      models_pk = row['attname']
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
      model.find_each(batch_size: 1000) do |ar_object|
        current_object_id = ar_object[models_pk]
        neo4j_node = get_node model.table_name, models_pk, ar_object[models_pk]

        ar_object.attributes.each do |attr|
            if attr[1].is_a?(Date) or attr[1].is_a?(DateTime) or attr[1].is_a?(Time)
              attr[1] = attr[1].to_time.to_i
            elsif attr[1].is_a? Numeric
              attr[1] = attr[1].to_f
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
