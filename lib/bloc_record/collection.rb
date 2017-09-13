module BlocRecord
  class Collection < Array #class collection inherits from Array
    # Person.where(boat: true).update_all(boat: false)

    def update_all(updates) # take an array, updates
      # self.map(&:id.to_proc)
      # self.map {|x| x.id}
      ids = self.map(&:id) # ids of all the rows within Person table where boat = true
      # If there are items in the array then we use the update method attached to the objects inside the Array(it would look like Entry.update) and return true. #Otherwise we return false to signify that nothing was updated.
      self.any? ? self.first.class.update(ids, updates) : false
    end

    # e.g Person.where(first_name: 'John').take
    # the query Person.where(first_name: 'John') will return an array of rows where first_name = John is true.
    # If there are no Johns in Person table the array will be empty
    # [rows_where_name_is_equal_to_John].take
    def take(limit=1)
      if self.any? #if array in not empty
        self[0...limit]
      else
        nil # if array is empty, return nil
      end
    end

    # Person.where(first_name: 'John').where(last_name: 'Smith');
    def where(*args)
      ids = self.map(&:id) # ids of all records/rows where first_name = John
      if args.count > 1
        expression = args.shift
        params = args
      else
        case args.first
        when String # "last_name = Smith"
          expression = args.first
        when Hash # "last_name: 'Smith'"
          expression_hash = BlocRecord::Utility.convert_keys(args.first)
          expression = expression_hash.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" AND ") #"last_name = Smith"
        end
      end
      string = "id IN (#{ids.join ","}) AND #{expression}"
      self.any? ? self.first.class.where(string) : false # call where method in bloc_record/selection.rb
    end

    # Person.where(first_name: 'John').not(last_name: 'Smith');
    def not(*args)
      ids = self.map(&:id) # array of record/row ids where first_name = Jane
      if args.count > 1
        expression = args.shift
        params = args
      else
        case args.first
        when String # "last_name = Smith"
          expression = args.first
        when Hash # "last_name: 'Smith'"
          expression_hash = BlocRecord::Utility.convert_keys(args.first)
          expression = expression_hash.map { |key, value| "NOT #{key} = #{BlocRecord::Utility.sql_strings(value)}"}.join(" AND ")
        end
      end
      string = "id IN (#{ids.join ","}) AND #{expression}"
      self.any? ? self.first.class.where(string) : false
    end

    # Entry.where(name: "Kate Smith").destroy_all
    # Entry.where(name: "Kate Smith") will return an array of rows where name = Kate Smith
    def destroy(*args)
      ids = self.map(&:id)
      self.any? ? self.first.class.destroy(ids.first) : false
    end

    def destroy_all
      self.each do |element|
        element.destroy
        puts "#{element} was deleted from the database"
      end
    end
  end
end
