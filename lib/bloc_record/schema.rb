# schema.rb, will contain information about the database schema
# It will translate between one SQL table and one Ruby class.
require 'sqlite3'
require 'bloc_record/utility'

module Schema
  # if we have a BookAuthor class, BookAuthor.table would return book_author
  def table
    # 1 - In the BlocRecord module, there is a Utility class that has a method called underscore.
    BlocRecord::Utility.underscore(name)
  end

  # iterates through the columns in a database table.
  # add the name and type of each column as a key-value pair
  # schema method uses the lazy loading design pattern, which means @schema isn't calculated until the first time it is needed.
  def schema
    unless @schema
      @schema = {}
      connection.table_info(table) do |col|
        @schema[col["name"]] = col["type"]
      end
    end
    @schema
  end

  # return the column names of a table, as an array => ["id", "name", "age"].
  def columns
    schema.keys
  end

  # return the column names except 'id'
  # used to make updates, as a general rule never change the id.
  def attributes
    columns - ["id"]
  end

  # returns a count of records/rows in a table.
  def count
    # execute is a SQLite3::Database instance method. It takes a SQL statement, executes it.
    # SELECT statement up to the terminator(SQL) is stored in a String and used wherever the <<- is
    # [0][0] extracts the first column of the first row, which will contain the count.
    connection.execute(<<-SQL)[0][0]
      SELECT COUNT(*) FROM #{table}
    SQL
  end
end
