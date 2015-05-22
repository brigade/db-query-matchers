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
        end.to raise_error
      end

      it 'lists the queries made in the error message' do
        expect do
          expect { subject }.to_not make_database_queries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                           /SELECT.*FROM.*cats/)
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
      context 'and the count matches' do
        it 'matches true' do
          expect { subject }.to make_database_queries(count: 1)
        end
      end

      context 'and the count does not match' do
        it 'raises an error' do
          expect do
            expect { subject }.to make_database_queries(count: 2)
          end.to raise_error
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
  end

  context 'when no queries are made' do
    subject { 'hi' }

    it 'matches true when using `to_not`' do
      expect { subject }.to_not make_database_queries
    end

    it 'raises an error when using `to`' do
      expect do
        expect { subject }.to make_database_queries
      end.to raise_error
    end

    it 'has a readable error message' do
      expect do
        expect { subject }.to make_database_queries
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
                         /expected queries, but none were made/)
    end
  end
end
