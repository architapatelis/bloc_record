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

  # myAddressBook = AddressBook.find_by("name", "My Address Book")
  def find_by(attribute, value)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    data = Hash[columns.zip(row)]
    new(data)
  end
end
