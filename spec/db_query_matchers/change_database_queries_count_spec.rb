require 'spec_helper'

describe '#change_database_queries_count' do
  before do
    Post.destroy_all
    Author.destroy_all
  end

  it 'matches when there is an N+1 redundancy' do
    Post.create!(author: Author.create!)
    expect do
      Post.create!(author: Author.create!)
    end.to change_database_queries_count(by: 1) { Post.all.each(&:author) }
  end

  it 'raises an error when there is no N+1 redundancy' do
    Post.create!(author: Author.create!)
    expect do
      expect do
        Post.create!(author: Author.create!)
      end.not_to change_database_queries_count { Post.all.each(&:author) }
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
      /\+SELECT/)
  end

  it 'matches when there is no N+1 redundancy' do
    Post.create!(author: Author.create!)
    expect do
      Post.create!(author: Author.create!)
    end.not_to change_database_queries_count(by: 1) { Post.includes(:author).each(&:author) }
  end

  it 'raises an error when there is an N+1 redundancy' do
    Post.create!(author: Author.create!)
    expect do
      expect do
        Post.create!(author: Author.create!)
      end.to change_database_queries_count { Post.includes(:author).each(&:author) }
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
      /\+SELECT/)
  end
end
