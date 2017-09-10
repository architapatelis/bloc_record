# the ability to find and return a record based on the record's id.
require 'sqlite3'

module Selection
  # to get data/rows of multiple ids
  # The *, splat operator, will combine any number of arguments into an array.
  # find(4, 8, 15, 16, 23, 42) would place those numbers in the array ids.
  def find(*ids)
    if ids.length == 1
      find_one(ids.first)
    else
      ids.each do |id|
        if id.is_a?(Integer) && id > 0
          next
        else
          puts "Ids must be numbers greater than 0. Try again"
        end
      end
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(rows)
    end
  end

  # used for example: character = Character.find(7)
  def find_one(id)
    if id.is_a?(Integer) && id > 0
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id = #{id};
      SQL

      # converts a row into an object
      init_object_from_row(row)
    else
      puts "Id must be a number greater than 0, Try again"
    end
  end

  # myAddressBook = AddressBook.find_by("name", "My Address Book")
  def find_by(attribute, value)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    # converts a row into an object
    init_object_from_row(row)
  end

  # return more than one random object
  # like find, this method returns either one object or an array of objects.
  def take(num=1)
    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    # LIMIT tells SQLite to only return one row.
    # random () returns a random integer
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  # get newest record
  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  # get oldest record
  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  # Contact.find_each(start: 2000, batch_size: 2000)
  def find_each(options = {})
    rows = retrieve_records(options) #private method

    rows.each do |row|
      init_object_from_row(row)
    end
  end

  def find_in_batches(options={})
    rows = retrieve_records(options) #private method

    row_array = rows_to_array(rows)
    row_array
  end

# ******************************************************************************

  private
  # converts a row into an object
  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  # Given an array of rows, this method maps the rows to an array of corresponding objects.
  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end


  def method_missing(m, *args) # m refers to name_of_method
    # e.g. find_by_name
    if m.match(/find_by_/)
      dynamic_name = m.to_s.split('find_by_')[1] # dynamic_name = name
      if columns.include?(dynamic_name) #if table includes a column called 'name'
        find_by(dynamic_name, *args) # find_by(name, *args)
      else
        raise "#{m} is not a valid method."
      end
    end
  end

  def retrieve_records(options)
    start = options.has_key?(:start) ? options[:start] : nil # start at 2000
    batch_size = options.has_key?(:batch_size) ? options[:batch_size] : nil #batch_size is 2000, (from 2001 to at most 4000)
    if start != nil && batch_size != nil
      # LIMIT 2000 OFFSET 2000
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{batch_size} OFFSET #{start};
      SQL
    # Contact.find_each(batch_size: 2000)
    # start at first row, and go at most up to batch_size
    elsif start == nil && batch_size != nil
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{batch_size};
      SQL
    # Contact.find_each(start: 2000)
    # from 2001 to end of table
    # cant not set OFFSET without LIMIT, therefore set LIMIT to -1
    elsif start != nil && batch_size == nil
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT -1 OFFSET #{start};
      SQL
    # no start or batch_size given
    # list all columns in a table
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table};
      SQL
    end
  end
end
