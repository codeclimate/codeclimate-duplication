require 'spec_helper'
require 'cc/engine/analyzers/ruby/main'
require 'flay'
require 'tmpdir'

module CC::Engine::Analyzers::Ruby
  describe Main do
    before { @code = Dir.mktmpdir }

    describe "#run" do
      it "prints an issue" do
        create_source_file("foo.rb", <<-EORUBY)
          describe '#ruby?' do
            before { subject.type = 'ruby' }

            it 'returns true' do
              expect(subject.ruby?).to be true
            end
          end

          describe '#js?' do
            before { subject.type = 'js' }

            it 'returns true' do
              expect(subject.js?).to be true
            end
          end
        EORUBY

        assert_equal run_engine, printed_issues
      end

      def create_source_file(path, content)
        File.write(File.join(@code, path), content)
      end

      def run_engine(config = nil)
        io = StringIO.new

        engine = ::CC::Engine::Analyzers::Ruby::Main.new(directory: @code, engine_config: config)
        reporter = ::CC::Engine::Analyzers::Reporter.new(@code, engine, io)

        reporter.run

        io.string
      end

      def first_issue
        {"type":"issue","check_name":"Similar code","description":"Duplication found in iter","categories":["Duplication"],"location":{"path":"foo.rb","lines":{"begin":1,"end":5}},"remediation_points": 360000, "other_locations":[{"path":"foo.rb","lines":{"begin":9,"end":13}}], "content": {"body": read_up}}
      end

      def printed_issues
        first_issue.to_json + "\0\n"
      end
    end
  end
end
