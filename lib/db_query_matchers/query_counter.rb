module DBQueryMatchers
  # Counter to keep track of the number of queries caused by running a piece of
  # code. Closely tied to the `:make_database_queries` matcher, this class is
  # designed to be a consumer of `sql.active_record` events.
  #
  # @example
  #   counter = DBQueryMatchers::QueryCounter.new
  #   ActiveSupport::Notifications.subscribed(counter.to_proc,
  #                                          'sql.active_record') do
  #     # run code here
  #   end
  #   puts counter.count          # prints the number of queries made
  #   puts counter.log.join(', ') # prints all queries made
  #
  # @see http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html#module-ActiveSupport::Notifications-label-Temporary+Subscriptions
  class QueryCounter
    attr_reader :count, :log

    def initialize(options = {})
      if options[:manipulative]
        @matches = [/^\ *(INSERT|UPDATE|DELETE\ FROM)/]
      end
      if options[:matching]
        @matches ||= []
        case options[:matching]
        when Regexp
          @matches << options[:matching]
        when String
          @matches << Regexp.new(Regexp.escape(options[:matching]))
        end
      end
      @count = 0
      @log   = []
    end

    # Turns a QueryCounter instance into a lambda. Designed to be used when
    # subscribing to events through the ActiveSupport::Notifications module.
    #
    # @return [Proc]
    def to_proc
      lambda(&method(:callback))
    end

    # Method called from the ActiveSupport::Notifications module (through the
    # lambda created by `to_proc`) when an SQL query is made.
    #
    # @param _name       [String] name of the event
    # @param _start      [Time]   when the instrumented block started execution
    # @param _finish     [Time]   when the instrumented block ended execution
    # @param _message_id [String] unique ID for this notification
    # @param payload    [Hash]   the payload
    def callback(_name, _start,  _finish, _message_id, payload)
      return if @matches && !any_match?(@matches, payload[:sql])
      return if any_match?(DBQueryMatchers.configuration.ignores, payload[:sql])
      return if DBQueryMatchers.configuration.schemaless && payload[:name] == "SCHEMA"

      count_query
      log_query(payload)

      DBQueryMatchers.configuration.on_query_counted.call(payload)
    end

    private

    def any_match?(patterns, sql)
      patterns.any? { |pattern| sql =~ pattern }
    end

    def count_query
      @count += 1
    end

    def log_query(payload)
      binds =
        unless (payload[:binds] || []).empty?
          casted_params = type_casted_binds(payload[:type_casted_binds])
          "  " + payload[:binds].zip(casted_params).map { |attr, value|
            render_bind(attr, value)
          }.inspect
        end

      filtered_backtrace =
        if DBQueryMatchers.configuration.log_backtrace
          "\n#{DBQueryMatchers.configuration.backtrace_filter.call(caller).join("\n")}\n"
        end

      @log << "#{payload[:sql].strip}#{binds}#{filtered_backtrace}"
    end

    def type_casted_binds(casted_binds)
      casted_binds.respond_to?(:call) ? casted_binds.call : casted_binds
    end

    def render_bind(attr, value)
      if attr.is_a?(Array)
        attr = attr.first
      elsif attr.type.binary? && attr.value
        value = "<#{attr.value_for_database.to_s.bytesize} bytes of binary data>"
      end

      [attr && attr.name, value]
    end
  end
end
