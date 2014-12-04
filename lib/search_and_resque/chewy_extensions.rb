module SearchAndResque
  module ChewyExtensions
    module ChewyType
      extend ActiveSupport::Concern

      module ClassMethods
        def delete!(ids)
          filter(:term => {:_id => ids}).delete_all
        end
      end
    end
  end
end
