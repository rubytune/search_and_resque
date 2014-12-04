module SearchAndResque
  class Queue
    class << self
      attr_accessor :queue
    end

    def self.perform(index_name, type_name, action, ids)
      index = Chewy::Index.subclasses.find{ |ind| ind.index_name == index_name }
      type = index.types.find{ |t| t.type_name == type_name }
      type.send(action, ids)
    end

    def self.enqueue_update(type, ids)
      unless ids.empty?
        Resque.enqueue(self, type.index.index_name, type.type_name, :import!, ids)
      end
    end
    
    def self.enqueue_delete(type, ids)
      unless ids.empty?
        Resque.enqueue(self, type.index.index_name, type.type_name, :delete!, ids)
      end
    end
  end
end
