# utility.rb, will contain some general, reusable utility functions for transforming data.
module BlocRecord

  module Utility
    #1 - self refers to the Utility class
    extend self
    # underscore is a class method
    # will convert TextLikeThis into text_like_this.
    # We'll need this to maintain proper conventions: Ruby class names are camel case, while SQL table names are snake case.
    def underscore(camel_cased_word)
      #2 replaces any double colons with a slash using gsub
      #  string = "SomeModule::SomeClass".gsub(/::/, '/')
      string = camel_cased_word.gsub(/::/, '/') #=> "SomeModule/SomeClass"
      #3 inserts an underscore between any all-caps class prefixes (like acronyms) and other words
      string.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2') #=> nil
      #4 inserts an underscore between any camelcased words
      string.gsub!(/([a-z\d])([A-Z])/,'\1_\2') #=> "Some_Module/Some_Class"
      #5 replaces any - with _ by using tr method
      string.tr!("-", "_") #=> nil
      #6 makes the string lowercase
      string.downcase #=> "some_module/some_class"
    end

    # converts String or Numeric input into an appropriately formatted SQL string
    def sql_strings(value)
      case value
      when String
        "'#{value}'"
      when Numeric
        value.to_s
      else
        "null"
      end
    end

    # takes an options hash and converts all the keys to string keys
    def convert_keys(options)
      options.keys.each {|k| options[k.to_s] = options.delete(k) if k.kind_of?(Symbol)}
      options
    end

    # converts an object's instance variables to a Hash
    def instance_variables_to_hash(obj)
      Hash[obj.instance_variables.map{ |var| ["#{var.to_s.delete('@')}", obj.instance_variable_get(var.to_s)]}]
    end

    def reload_obj(dirty_obj)
      # takes an object, finds its database record using the find method in the  Selection module.
      persisted_obj = dirty_obj.class.find_one(dirty_obj.id)
      # overwrites the instance variable values with the stored values from the database.
      dirty_obj.instance_variables.each do |instance_variable|
        dirty_obj.instance_variable_set(instance_variable, persisted_obj.instance_variable_get(instance_variable))
      end
    end
  end
end
