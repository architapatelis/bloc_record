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
  end
end
