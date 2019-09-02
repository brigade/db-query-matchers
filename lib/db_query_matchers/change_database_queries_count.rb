require 'rspec/core'
require 'rspec/expectations'

# Can be used to spec N+1 redundancies.
#
# @example
#   expect { Post.create! }.to change_database_queries_count(by: 1) { Post.all.each(&:comments) }
#
# @example
#   expect { Post.create! }.not_to change_database_queries_count { Post.includes(:comments).each(&:comments) }
#
# @see DBQueryMatchers::QueryCounter
RSpec::Matchers.define :change_database_queries_count do |options = {}|
  if RSpec::Core::Version::STRING =~ /^2/
    def self.failure_message_when_negated(&block)
      failure_message_for_should_not(&block)
    end

    def self.failure_message(&block)
      failure_message_for_should(&block)
    end

    def supports_block_expectations?
      true
    end
  else
    supports_block_expectations
  end

  def diff
    Diffy::Diff.new(@before_counter.log.join("\n") + "\n", @after_counter.log.join("\n") + "\n")
  end

  define_method :matches? do |subject|
    @before_counter = DBQueryMatchers::QueryCounter.new(options)
    @after_counter = DBQueryMatchers::QueryCounter.new(options)
    ActiveSupport::Notifications
      .subscribed(@before_counter.to_proc, DBQueryMatchers.configuration.db_event, &block_arg)
    subject.call
    ActiveSupport::Notifications
      .subscribed(@after_counter.to_proc, DBQueryMatchers.configuration.db_event, &block_arg)

    if options[:by]
      options[:by] == @after_counter.count - @before_counter.count
    else
      @before_counter.count != @after_counter.count
    end
  end

  failure_message_when_negated do |_|
    fail if options[:by]
    <<-EOS
expected the same number of queries to be made, but #{@before_counter.count} has changed to #{@after_counter.count}:
#{diff}
    EOS
  end

  failure_message do |_|
    if options[:by]
      <<-EOS
expected the number of queries to change by #{options[:by]}, but it has changed by #{@after_counter.count - @before_counter.count}:
#{diff}
      EOS
    else
      <<-EOS
expected the number of queries to change, but it has not changed:
#{diff}
      EOS
    end
  end
end
