# This file will work directly with the database
require 'sqlite3'
require 'bloc_record/schema'

# self.included is called whenever this module is included.
# When this happens, extend adds the ClassMethods methods to Persistence.
module Persistence
  def self.included(base)
    base.extend(ClassMethods)
  end

  # rescue from failed attempts to save.
  def save
    self.save! rescue false
  end

  def save!
    # if a model object is created without invoking create method, then it won't have an id
    # therefore delegate the work to create if there's no id set:
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
      # copy whatever is stored in the database back to the model object.
      # This is necessary in case SQL rejected or changed any of the data.
      BlocRecord::Utility.reload_obj(self)
      return true
    end

    fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

    # save data to database using UPDATE statement.
    self.class.connection.execute <<-SQL
      UPDATE #{self.class.table}
      SET #{fields}
      WHERE id = #{self.id};
    SQL

    true # return true to indicate success.
  end

  module ClassMethods
    # attrs is a hash
    # look at checkpoint 2 for example.
    def create(attrs)
      # convert keys is attrs hash to String type.
      attrs = BlocRecord::Utility.convert_keys(attrs)
      attrs.delete "id"
      # attributes, from schema.rb is an array of columns without 'id' column.
      # vals is an array of 'values' from key/value pairs.
      vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }
      # INSERTS rows into the database.
      connection.execute <<-SQL
        INSERT INTO #{table} (#{attributes.join ","})
        VALUES (#{vals.join ","});
      SQL

      # data, a hash of attributes and values.
      data = Hash[attributes.zip attrs.values]
      # retrieve the id and add it to the data hash.
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      # pass the hash to new which creates a new object.
      new(data)
    end
  end
end
