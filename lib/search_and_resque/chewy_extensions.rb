module SearchAndResque
  module ChewyExtensions
    module ChewyType
      extend ActiveSupport::Concern

      module ClassMethods
        def delete!(ids)
          filter(:ids => {:values => ids}).delete_all
        end
      end
    end
  end
end
