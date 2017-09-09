require 'sqlite3'

#A new Database object will be initialized from the file the first time connection is called.
# We'll interact with this object later to read and write data.
module Connection
  def connection
    @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
  end
end
