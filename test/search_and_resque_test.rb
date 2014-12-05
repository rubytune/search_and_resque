require 'active_record'

test_framework = if ActiveRecord::VERSION::STRING >= "4.1"
  require 'minitest/autorun'
  MiniTest::Test
else
  require 'test/unit'
  Test::Unit::TestCase
end

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'chewy'
require 'resque'
require 'search_and_resque'

def connect!
  ActiveRecord::Base.establish_connection :adapter => 'sqlite3', database: ':memory:'
end

def setup!
  connect!
  ActiveRecord::Base.connection.execute 'CREATE TABLE books (id INTEGER NOT NULL PRIMARY KEY, deleted_at DATETIME, title STRING, content STRING)'
end

setup!

class Book < ActiveRecord::Base
  search_and_resque :books
end

class SearchAndResqueTestIndex < Chewy::Index
  define_type Book, :name => 'books' do
    field :title
    field :content
  end
end

Chewy.configuration = {
  host: 'localhost:9200'
}

SearchAndResque.index_name = 'search_and_resque_test'
SearchAndResque::Queue.queue = :search_and_resque_test_queue

Resque.inline = true


class SearchAndResqueTest < test_framework
  def setup
    SearchAndResqueTestIndex.purge
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.execute "DELETE FROM #{table}"
    end
  end

  def test_index_update_on_create_and_destroy
    book = Book.create
    assert_equal 1, SearchAndResqueTestIndex::Books.total_count

    book.destroy
    assert_equal 0, SearchAndResqueTestIndex::Books.total_count
  end
end
