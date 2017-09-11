#Just to remember that the require and load are 'file-level' methods used to "read" and parse files,
# whereas include and extend are 'language-level' methods that can extend your class with other modules.
require 'bloc_record/utility'
require 'bloc_record/schema'
require 'bloc_record/persistence'
require 'bloc_record/selection'
require 'bloc_record/connection'


module BlocRecord
  # base class named… Base. Users of our ORM will subclass Base when creating their model objects.
  class Base
    ## include will allow methods defined in Persistence module to be used as instance methods. So any instance of class Base can use them.
    include Persistence
    extend Selection
    extend Schema
    extend Connection

    def initialize(options={})
      # converts all the keys to string keys
      options = BlocRecord::Utility.convert_keys(options)

      # If BookAuthor inherits from Base, self.class would be equivalent to BookAuthor.class
      # iterate over array of column names. => ["id", "name", "age"]
      self.class.columns.each do |col|
        # send, is an Object method. it sends the column name to attr_accessor
        self.class.send(:attr_accessor, col)
        # set the instance variable. so that @name = 'Arch'
        self.instance_variable_set("@#{col}", options[col])
      end
    end
  end
end
