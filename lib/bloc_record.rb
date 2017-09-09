# add the ability to connect to a SQLite3 database.
module BlocRecord
  # this filename will be stored for later.
  def self.connect_to(filename)
    @database_filename = filename
  end

  def self.database_filename
    @database_filename
  end
end
