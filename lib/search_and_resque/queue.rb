module SearchAndResque
  class Queue
    class << self
      attr_accessor :queue
    end

    def self.perform(type_name, action, ids)
      type = SearchAndResque.index.types.find{ |t| t.type_name == type_name }
      type.send(action, ids)
    end

    def self.enqueue_update(type_name, ids)
      unless ids.empty?
        Resque.enqueue(self, type_name, :import!, ids)
      end
    end
    
    def self.enqueue_delete(type_name, ids)
      unless ids.empty?
        Resque.enqueue(self, type_name, :delete!, ids)
      end
    end
  end
end
