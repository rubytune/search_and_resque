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
  ActiveRecord::Base.connection.execute 'CREATE TABLE books (id INTEGER NOT NULL PRIMARY KEY, deleted_at DATETIME, title STRING)'
  ActiveRecord::Base.connection.execute 'CREATE TABLE films (id INTEGER NOT NULL PRIMARY KEY, deleted_at DATETIME, title STRING, director STRING)'
end

setup!

class Book < ActiveRecord::Base
  search_and_resque :books
end

class Film < ActiveRecord::Base
  search_and_resque :films, :if => ->{ title_changed? }
end

class SearchAndResqueTestIndex < Chewy::Index
  define_type Book, :name => 'books' do
    field :title
  end

  define_type Film, :name => 'films' do
    field :title
    field :director
  end
end

Chewy.configuration = {
  host: 'localhost:9200'
}

SearchAndResque.chewy_index_name = :SearchAndResqueTestIndex
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
    assert_equal 1, SearchAndResqueTestIndex::Books.filter(:ids => {:values => [book.id]}).total_count

    book.destroy
    assert_equal 0, SearchAndResqueTestIndex::Books.filter(:ids => {:values => [book.id]}).total_count
  end

  def test_index_update_on_save
    book = Book.create(:title => 'one')

    book.update_attributes(:title => 'two')
    assert_equal 'two', SearchAndResqueTestIndex::Books.filter(:ids => {:values => [book.id]}).first.title
  end

  def test_failing_conditional_index_update
    film = Film.create(:title => 'one', :director => 'two')

    film.update_attributes(:director => 'three')
    assert_equal 'two', SearchAndResqueTestIndex::Films.filter(:ids => {:values => [film.id]}).first.director
  end

  def test_succeeding_conditional_index_update
    film = Film.create(:title => 'one', :director => 'two')

    film.update_attributes(:title => 'three', :director => 'four')
    assert_equal 'four', SearchAndResqueTestIndex::Films.filter(:ids => {:values => [film.id]}).first.director
  end
end
