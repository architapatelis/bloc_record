# This file will work directly with the database
require 'sqlite3'
require 'bloc_record/schema'

# self.included is called whenever this module is included.
# When this happens, extend adds the ClassMethods methods to Persistence.
# methods that are not witin ClassMethods, are instance methods:
  # e = Entry.first
  # e is an instance of Entry Class
  # therefore, we can use e.destroy or e.update_attribute.
  # remember e.destory is like saying, self.class.destroy which is: Entry.destroy
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

  # update one attribute with an instance method
  # b = AddressBook.first
  # b.update_attribute(:name, "My Favorite Address Book")
  def update_attribute(attribute, value)
    self.class.update(self.id, { attribute => value }) # call private update method
  end

  # e = Entry.first
  # e.update_attributes(name: "Ben", phone_numer: 949-858-7878)
  def update_attributes(updates)
    self.class.update(self.id, updates) # call private update method
  end

  # e = Entry.first
  # e.destroy
  def destroy
    self.class.destroy(self.id)
  end

  # e = Entry.all[3]
  # e.update_name('Ben Johnson')
  def method_missing(m, *args) # m is method_name
    if m.match(/update_/)
      attribute = m.to_s.split('update_')[1] # attribute = name
      ## e.class is Entry
      # Entry.column.include?(name)
      if self.class.columns.include?(attribute)
        self.class.update(self.id, { attribute => args.first } )
      else
        puts "#{attribute} does not exist in the database."
      end
    end
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

    def update_all(updates)
      update(nil, updates)
    end

    # people = { 1 => { "first_name" => "David" }, 2 => { "first_name" => "Jeremy" } }
    # Person.update(people.keys, people.values)
    def update(ids, updates)
      if updates.class == Array # update([1,2], [{"first_name"=>"David"}, {"first_name"=>"Jeremy"}])
        updates.each_with_index do |update, index|
          update(ids[index], update) # update(1, {"first_name"=>"David"})
        end
      elsif updates.class == Hash # e.g. update(ids, user_name: 'Samuel', group: 'expert')
        # convert the non-id parameters to an array.
        updates = BlocRecord::Utility.convert_keys(updates) # {"user_name"=>"Samuel", "group"=>"expert"}
        updates.delete "id"
        # convert updates to an array of strings where each string is in the format "KEY=VALUE".
        # ["user_name = Samuel", "group = expert"]
        updates_array = updates.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }

        # appending ids in the form of a string to the WHERE clause.
        if ids.class == Fixnum
          where_clause = "WHERE id = #{ids};"
        elsif ids.class == Array
          where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
        else
          where_clause = ";"
        end

        connection.execute <<-SQL
          UPDATE #{table}
          SET #{updates_array * ","} #{where_clause}
        SQL
        true
      end
    end

    # e.g. Entry.destroy(15)
    # or e.g. Entry.destroy(1,2,3)
    # remember splat operator(*), makes an array out of multiple arguments.
    def destroy(*id)
      if id.length > 1
        where_clause = "WHERE id IN (#{id.join(",")});"
      else
        where_clause = "WHERE id = #{id.first};"
      end
      connection.execute <<-SQL
        DELETE FROM #{table} #{where_clause}
      SQL
      true
    end

    # e.g. Entry.destroy_all or Entry.destroy_all(name: "Jane Doe")
    # DESTROY will apply to all records if the command isn't scoped using WHERE.
    def destroy_all(conditions_hash=nil)
      if conditions_hash && !conditions_hash.empty? # if conditions are given
        conditions_hash = BlocRecord::Utility.convert_keys(conditions_hash)
        conditions = conditions_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ") #"name = Jane"

        connection.execute <<-SQL
          DELETE FROM #{table}
          WHERE #{conditions};
        SQL
      else
        connection.execute <<-SQL
          DELETE FROM #{table}
        SQL
      end
      true
    end
  end
end
