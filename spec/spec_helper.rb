require 'db_query_matchers'
require 'active_record'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  ActiveRecord::Base.establish_connection adapter:  'sqlite3',
                                          database: ':memory:'

  ActiveRecord::Schema.define do
    self.verbose = false

    create_table :cats, :force => true do |t|
      t.column :name, :string
    end

    create_table :authors, :force => true

    create_table :posts, :force => true do |t|
      t.references :author
    end
  end
end
