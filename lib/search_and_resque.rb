require "search_and_resque/version"
require "search_and_resque/callbacks"
require "search_and_resque/queue"
require "search_and_resque/chewy_extensions"

module SearchAndResque
  extend ActiveSupport::Concern

  @queue = SearchAndResque::Queue

  def self.queue=(queue)
    @queue = queue
  end

  def self.queue
    @queue
  end

  def self.index_name=(name)
    @index_name = "#{name}"
  end

  def self.index_name
    @index_name
  end

  def self.chewy_index
    Object.const_get(index_name)
  end

  module ClassMethods
    def search_and_resque(type_name, options={})
      unless included_modules.include?(SearchAndResque::Callbacks)
        options[:if] ||= ->{ true }
        define_method(:should_update_elastic_search?, &options[:if])

        @elastic_search_type = "#{type_name}"

        include SearchAndResque::Callbacks
      end
    end
  end
end

ActiveRecord::Base.send :include, SearchAndResque
Chewy::Type.send :include, SearchAndResque::ChewyExtensions::ChewyType
