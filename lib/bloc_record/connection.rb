require 'sqlite3'
require 'pg'
#A new Database object will be initialized from the file the first time connection is called.
# We'll interact with this object later to read and write data.
module Connection
  def connection
    if BlocRecord.database_type == :sqlite3
      @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    elsif BlocRecord.database_type == :pg
      @connection ||= Postgres::Database.new(BlocRecord.database_filename)
    end
  end
end
