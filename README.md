# SearchAndResque

## Installation

Add these lines to your application's Gemfile:

    gem 'chewy'
    gem 'search_and_resque'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install search_and_resque

## Usage

```ruby
class Film < ActiveRecord::Base
  # Create after_save, after_destroy callbacks
  search_and_resque :films
end

class Document < ActiveRecord::Base
  # Create after_save, after_destroy callbacks, only run when document text has changed
  search_and_resque :documents, :if => ->{ contents_changed? }
end

class MyIndex < Chewy::Index
  define_type Film do
    field :title
  end
  
  define_type Document do
    field :contents
  end
end
```

Calling `search_and_resque` in a Rails model sets up `after_save`/`after_destroy` callbacks, which will enqueue Resque jobs to update (or delete from) the index.

## Configuration

`SearchAndResque.index_name` must be set by the environment, as well as `SearchAndResque::Queue.queue` (the queue name).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/search_and_resque/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
