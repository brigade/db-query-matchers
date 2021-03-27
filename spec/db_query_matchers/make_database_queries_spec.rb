require 'spec_helper'

describe '#make_database_queries' do
  context 'when queries are made' do
    subject { Cat.first }

    it 'matches true when using `to`' do
      expect { subject }.to make_database_queries
    end

    context 'when using `to_not`' do
      it 'raises an error' do
        expect do
          expect { subject }.to_not make_database_queries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      it 'lists the queries made in the error message' do
        expect do
          expect { subject }.to_not make_database_queries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                           /SELECT.*FROM.*cats/)
      end
    end

    context 'when there is an on_query_counted callback configured' do
      before do
        @callback_called = false

        DBQueryMatchers.configure do |config|
          config.on_query_counted = lambda do |payload|
            @callback_called = true
          end
        end
      end

      after { DBQueryMatchers.reset_configuration }

      it 'is called' do
        expect { subject }.to make_database_queries
        expect(@callback_called).to eq(true)
      end

      context 'with an `ignores` pattern' do
        before do
          DBQueryMatchers.configure do |config|
            config.ignores = ignores
          end
        end

        let(:ignores) { [/SELECT.*FROM.*cats/] }

        it 'is not called' do
          expect { subject }.not_to make_database_queries
          expect(@callback_called).to eq(false)
        end
      end
    end

    context 'when an `ignores` pattern is configured' do
      before do
        DBQueryMatchers.configure do |config|
          config.ignores = ignores
        end
      end

      after { DBQueryMatchers.reset_configuration }

      context 'when the pattern matches the query' do
        let(:ignores) { [/SELECT.*FROM.*cats/] }

        it 'ignores the query' do
          expect { subject }.to_not make_database_queries
        end
      end

      context 'when the pattern does not match the query' do
        let(:ignores) { [/SELECT.*FROM.*dogs/] }

        it 'does not ignore the query' do
          expect { subject }.to make_database_queries(count: 1)
        end
      end

      context 'with multiple patterns' do
        let(:ignores) { [/SELECT.*FROM.*cats/, /SELECT.*FROM.*dogs/] }

        it 'ignores the query' do
          expect { subject }.to_not make_database_queries
        end
      end
    end

    context 'when a `count` option is specified' do
      context 'when the count is a range' do
        context 'and it matches' do
          it 'matches true' do
            expect { subject }.to make_database_queries(count: 1..2)
          end
        end

        context 'and it does not match' do
          it 'raises an error' do
            expect do
              expect { subject }.to make_database_queries(count: 2..3)
            end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
          end
        end
      end

      context 'when the count is an integer' do
        context 'and it matches' do
          it 'matches true' do
            expect { subject }.to make_database_queries(count: 1)
          end
        end

        context 'and it does not match' do
          it 'raises an error' do
            expect do
              expect { subject }.to make_database_queries(count: 2)
            end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
          end

          it 'mentions the expected number of queries' do
            expect do
              expect { subject }.to make_database_queries(count: 2)
            end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                               /expected 2 queries/)
          end

          it 'mentions the actual number of queries' do
            expect do
              expect { subject }.to make_database_queries(count: 2)
            end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                               /but 1 was made/)
          end

          it 'lists the queries made in the error message' do
            expect do
              expect { subject }.to make_database_queries(count: 2)
            end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                               /SELECT.*FROM.*cats/)
          end
        end
      end
    end

    context 'when a `manipulative` option is as true' do
      context 'and there is a create query' do
        subject { Cat.create }

        it 'matches true' do
          expect { subject }.to make_database_queries(manipulative: true)
        end
      end

      context 'and there is an update query' do
        before do
          Cat.create if Cat.count == 0
        end

        subject { Cat.last.update name: 'Felix' }

        it 'matches true' do
          expect { subject }.to make_database_queries(manipulative: true)
        end
      end

      context 'and there is a destroy query' do
        before do
          Cat.create if Cat.count == 0
        end

        subject { Cat.last.destroy }

        it 'matches true' do
          expect { subject }.to make_database_queries(manipulative: true)
        end
      end

      context 'and there are no manipulative queries' do
        it 'raises an error' do
          expect do
            expect { subject }.to make_database_queries(manipulative: true)
          end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                             /expected queries, but none were made/)
        end
      end
    end

    context 'when a `unscoped` option is true' do
      shared_examples 'it raises an error' do
        it 'raises an error' do
          expect do
            expect { subject }.to make_database_queries(unscoped: true)
          end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                             /expected queries, but none were made/)
        end

        it 'does not raise with `to_not`' do
          expect { subject }.to_not make_database_queries(unscoped: true)
        end
      end

      before do
        Cat.create if Cat.count == 0
      end

      context 'and there is a query without a WHERE or LIMIT clause' do
        context 'SELECT' do
          subject { Cat.all.to_a }

          it 'matches true' do
            expect { subject }.to make_database_queries(unscoped: true)
          end

          it 'raises an error with `to_not`' do
            expect do
              expect { subject }.to_not make_database_queries(unscoped: true)
            end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                               /expected no queries, but 1 were made/)
          end
        end

        context 'DELETE' do
          subject { Cat.delete_all }

          it 'matches true' do
            expect { subject }.to make_database_queries(unscoped: true)
          end

          it 'raises an error with `to_not`' do
            expect do
              expect { subject }.to_not make_database_queries(unscoped: true)
            end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                               /expected no queries, but 1 were made/)
          end
        end

        context 'UPDATE' do
          subject { Cat.update_all(name: 'Nombre') }

          it 'matches true' do
            expect { subject }.to make_database_queries(unscoped: true)
          end

          it 'raises an error with `to_not`' do
            expect do
              expect { subject }.to_not make_database_queries(unscoped: true)
            end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                               /expected no queries, but 1 were made/)
          end
        end

        context 'INSERT' do
          context 'without INTO SELECT' do
            subject { Cat.create name: 'Joe' }

            it 'matches false' do
              expect { subject }.to_not make_database_queries(unscoped: true)
            end
          end

          context 'with INTO SELECT' do
            subject do
              Cat.connection.execute <<-SQL
                INSERT INTO "cats" SELECT * FROM "dogs";
              SQL
            end
            it 'matches true' do
              expect { subject }.to make_database_queries(unscoped: true)
            end

            it 'raises an error with `to`' do
              expect do
                expect { subject }.to_not make_database_queries(unscoped: true)
              end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                                 /expected no queries, but 1 were made/)
            end
          end
        end
      end

      context 'there is a limit clause' do
        context 'SELECT' do
          subject { Cat.all.limit(100).to_a }
          include_examples 'it raises an error'
        end

        context 'UPDATE' do
          subject { Cat.limit(10).update_all(name: 'Nombre') }
          include_examples 'it raises an error'
        end

        context 'DELETE' do
          subject do
            begin
              Cat.limit(100).delete_all
            rescue ActiveRecord::ActiveRecordError => e
              pending("delete_all doesn't support limits prior to ActiveRecord 5.2") if e.message.include?("delete_all doesn't support limit")
              raise
            end
          end

          include_examples 'it raises an error'
        end

        context 'INTO SELECT' do
          subject do
            Cat.connection.execute <<-SQL
              INSERT INTO "cats" SELECT * FROM "dogs" LIMIT 100;
            SQL
          end
          include_examples 'it raises an error'
        end
      end

      context 'there is a where clause' do
        context 'SELECT' do
          subject { Cat.where(name: 'Bob').to_a }
          include_examples 'it raises an error'
        end

        context 'UPDATE' do
          subject { Cat.where(name: 'Bob').update_all(name: 'Nombre') }
          include_examples 'it raises an error'
        end

        context 'DELETE' do
          subject { Cat.where(name: 'Bob').delete_all }
          include_examples 'it raises an error'
        end

        context 'INTO SELECT' do
          subject do
            Cat.connection.execute <<-SQL
              INSERT INTO "cats" SELECT * FROM "dogs" WHERE "dogs"."name" = 'Fido';
            SQL
          end
          include_examples 'it raises an error'
        end
      end

      context 'there is a where and limit clause' do
        context 'SELECT' do
          subject { Cat.where(name: 'Bob').limit(10).to_a }
          include_examples 'it raises an error'
        end

        context 'UPDATE' do
          subject { Cat.where(name: 'Bob').limit(10).update_all(name: 'Nombre') }
          include_examples 'it raises an error'
        end

        context 'DELETE' do
          subject do
            begin
              Cat.where(name: 'Bob').limit(10).delete_all
            rescue ActiveRecord::ActiveRecordError => e
              pending("delete_all doesn't support limits prior to ActiveRecord 5.2") if e.message.include?("delete_all doesn't support limit")
              raise
            end
          end

          include_examples 'it raises an error'
        end

        context 'INTO SELECT' do
          subject do
            Cat.connection.execute <<-SQL
              INSERT INTO "cats" SELECT * FROM "dogs" WHERE "dogs"."name" = 'Fido' LIMIT 10;
            SQL
          end
          include_examples 'it raises an error'
        end
      end
    end

    context 'when a `matching` option is specified' do
      context 'with a string matcher' do
        context 'and there is a query matching the matcher specified' do
          subject { Cat.create }

          it 'matches true' do
            expect { subject }.to make_database_queries(matching: 'INSERT')
          end
        end

        context 'and there are no queries matching the matcher specified' do
          it 'raises an error' do
            expect do
              expect { subject }.to make_database_queries(matching: 'INSERT')
            end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                    /expected queries, but none were made/)
          end
        end
      end

      context 'with a regexp matcher' do
        context 'and there is a query matching the matcher specified' do
          subject { Cat.create }

          it 'matches true' do
            expect { subject }.to make_database_queries(matching: /^\ *INSERT/)
          end
        end

        context 'and there are no queries matching the matcher specified' do
          it 'raises an error' do
            expect do
              expect { subject }.to make_database_queries(matching: /^\ *INSERT/)
            end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                    /expected queries, but none were made/)
          end
        end
      end
    end

    context 'when a `schemaless` option is true' do
      before do
        DBQueryMatchers.configure do |config|
          config.schemaless = true
        end
      end

      it 'does not count column information queries' do
        Cat.connection.schema_cache.clear!
        Cat.reset_column_information
        expect { subject }.to make_database_queries(count: 1)
      end
    end

    context 'when a `schemaless` option is false' do
      before do
        DBQueryMatchers.configure do |config|
          config.schemaless = false
        end
      end

      it 'does count column information queries' do
        Cat.reset_column_information
        expect { subject }.to make_database_queries(count: 2..4)
      end
    end

    context 'when a `log_backtrace` option is true' do
      before do
        DBQueryMatchers.configure do |config|
          config.log_backtrace = true
          config.backtrace_filter = Proc.new do |backtrace|
            backtrace.select { |line| line.start_with?(__FILE__) } # only show lines in this file
          end
        end
      end

      it 'logs the backtrace for the query' do
        expect do
          expect { subject }.not_to make_database_queries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError) do |e|
          expect(e.message).to match(/SELECT/)
          expect(e.message).to include(__FILE__)
        end
      end
    end

    context 'when a different db_event is configured' do
      before do
        DBQueryMatchers.configure do |config|
          config.db_event = 'other_event'
        end
      end

      after { DBQueryMatchers.reset_configuration }

      it 'does not respond to normal events' do
        expect { subject }.not_to make_database_queries
      end

      it 'responds to custom event' do
        expect {
          ActiveSupport::Notifications.publish 'other_event', Time.now, Time.now, 1, { sql: "FOO" }
        }.to make_database_queries(count: 1)
      end
    end
  end

  if Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new('6.0.0')
    context 'when a database_role is used' do
      subject { Cat.first }

      it 'matches true when the matching database role was used' do
        expect do
          ActiveRecord::Base.connected_to(:reading) do
            subject
          end
        end.to make_database_queries(database_role: :reading)
      end

      it 'matches false when a non-matching database role was used' do
        expect do
          ActiveRecord::Base.connected_to(:reading) do
            subject
          end
        end.to make_database_queries(database_role: :writing)
      end
    end
  end

  context 'when no queries are made' do
    subject { 'hi' }

    it 'matches true when using `to_not`' do
      expect { subject }.to_not make_database_queries
    end

    it 'raises an error when using `to`' do
      expect do
        expect { subject }.to make_database_queries
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    it 'has a readable error message' do
      expect do
        expect { subject }.to make_database_queries
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                         /expected queries, but none were made/)
    end
  end

  context 'when some other expectation in the block fails' do
    subject {
      Cat.first
      raise RSpec::Expectations::ExpectationNotMetError.new('other')
    }

    it 'reraises the error' do
      expect do
        expect { subject }.to make_database_queries(count: 1)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /other/)
    end
  end

end
