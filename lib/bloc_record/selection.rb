# the ability to find and return a record based on the record's id.
require 'sqlite3'

module Selection
  # used for example: character = Character.find(7)
  def find(id)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL

    data = Hash[columns.zip(row)]
    new(data)
  end
end
