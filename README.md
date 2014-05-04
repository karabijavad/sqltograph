bundle && echo "DATABASE_URL=postgres://127.0.0.1/db_to_be_converted" > .env && bundle exec rake sqltograph
