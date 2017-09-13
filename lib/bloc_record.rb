# add the ability to connect to a SQLite3 database.
module BlocRecord
  #  Support PostgreSQL in addition to SQLite
  #  BlocRecord.connect_to("db/address_bloc.db", :pg)
  # BlocRecord.connect_to("db/address_bloc.db", :sqlite3)
  def self.connect_to(filename, type)
    @database_filename = filename
    @database_type = type
  end

  def self.database_filename
    @database_filename
  end

  def self.database_type
    @database_type
  end
end
