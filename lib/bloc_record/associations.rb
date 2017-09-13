require 'sqlite3'

# Inflector transforms words from:
  # singular to plural,
  # class names to table names,
  # modularized class names to ones without,
  # and class names to foreign keys.
require 'active_support/inflector'

module Associations
  # e.g. of association is :entries
  # e.g. self is an instance of AddressBook.
  # therefore self has_many :entries
  # has_many :entries
  def has_many(association)
    #1 at runtime define_method adds an instance method called entries to the AddressBook class.
    define_method(association) do
      #2 e.g. SELECT * FROM entry WHERE address_book_id = 123
      rows = self.class.connection.execute <<-SQL
        SELECT * FROM #{association.to_s.singularize}
        WHERE #{self.class.table}_id = #{self.id}
      SQL

      #3 we create a new class name.
      # classify creates the appropriate string name ('Entry'),
      # and constantize converts the string to the actual class (the Entry class).
      class_name = association.to_s.classify.constantize
      # create empty collection array
      collection = BlocRecord::Collection.new

      #4 iterate each SQL record returned, and serialize it into an Entry object, which is added to collection.
      rows.each do |row|
        collection << class_name.new(Hash[class_name.columns.zip(row)])
      end

      #5 return an array of entries where the address_book_id = 123
      collection
    end
  end

  # belongs_to :address_book
  # self is an instance of class Entry
  def belongs_to(association)
    define_method(association) do
      association_name = association.to_s # address_book
      # SELECT * FROM address_book WHERE id = 1
      # only one record/row will be returned.
      row = self.class.connection.get_first_row <<-SQL
        SELECT * FROM #{association_name}
        WHERE id = #{self.send(association_name + "_id")}
      SQL

      # class_name = AddressBook
      class_name = association_name.classify.constantize

      # because there's only one object, we don't create a Collection; we just return the serialized object.
      if row
        data = Hash[class_name.columns.zip(row)]
        class_name.new(data)
      end
    end
  end

  # e.g. a user has_one :account
  # association is account
  # self is an instance of class User
  def has_one(association)
    define_method(association) do
      # SELECT * FROM account WHERE user_id = 123
      row = self.class.connection.get_first_row <<-SQL
        SELECT * FROM #{association.to_s}
        WHERE #{self.class.table}_id = #{self.id}
      SQL

      class_name = association.to_s.classify.constantize

      # because there's only one object, we don't create a Collection; we just return the serialized object.
      if row
        data = Hash[class_name.columns.zip(row)]
        class_name.new(data)
      end
    end
  end
end
