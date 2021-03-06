module SearchAndResque
  module Callbacks
    extend ActiveSupport::Concern

    module ClassMethods
      def enqueue_elastic_search_update(ids)
        ids = Array(ids).map{ |x| x.is_a?(ActiveRecord::Base) ? x.id : x }
        SearchAndResque.queue.enqueue_update(elastic_search_type, ids)
      end

      def enqueue_elastic_search_delete(ids)
        ids = Array(ids).map{ |x| x.is_a?(ActiveRecord::Base) ? x.id : x }
        SearchAndResque.queue.enqueue_delete(elastic_search_type, ids)
      end

      # e.g.
      #     Model.will_update_all(@records) do
      #       ...
      #       @records.update_all(...)
      #       ...
      #     end
      def will_update_all(ids)
        begin
          skip_callback(:save, :after, :enqueue_elastic_search_update)
          transaction do
            yield if block_given?
            enqueue_elastic_search_update(ids) unless ids.empty?
          end
        ensure
          set_callback(:save, :after, :enqueue_elastic_search_update)
        end
      end

      # e.g.
      #     Model.will_delete_all(@records) do
      #       ...
      #       @records.delete_all
      #       ...
      #     end
      def will_delete_all(ids)
        begin
          skip_callback(:destroy, :after, :enqueue_elastic_search_delete)
          transaction do
            yield if block_given?
            enqueue_elastic_search_delete(ids) unless ids.empty?
          end
        ensure
          set_callback(:destroy, :after, :enqueue_elastic_search_delete)
        end
      end
    end

    def enqueue_elastic_search_update
      if should_update_elastic_search?
        self.class.enqueue_elastic_search_update(elastic_search_id)
      end
    end

    def enqueue_elastic_search_delete
      self.class.enqueue_elastic_search_delete(elastic_search_id)
    end
  end
end
