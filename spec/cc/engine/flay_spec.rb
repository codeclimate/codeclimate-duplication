require "spec_helper"
require "cc/engine/flay"
require "flay"
require "tmpdir"

module CC::Engine
  describe Flay do
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

        assert_equal run_engine, "{\"type\":\"issue\",\"check_name\":\"Similar code\",\"description\":\"Duplication found in iter\",\"categories\":[\"Duplication\"],\"location\":{\"path\":\"" + @code + "/foo.rb\",\"lines\":{\"begin\":1,\"end\":1}}}\0\n{\"type\":\"issue\",\"check_name\":\"Similar code\",\"description\":\"Duplication found in iter\",\"categories\":[\"Duplication\"],\"location\":{\"path\":\"" + @code + "/foo.rb\",\"lines\":{\"begin\":9,\"end\":9}}}\0\n"
      end

      def create_source_file(path, content)
        File.write(File.join(@code, path), content)
      end

      def run_engine(config = nil)
        $stdout = io = StringIO.new

        flay = Flay.new(directory: @code, engine_config: config, io: io)
        flay.run

        io.string
      end
    end
  end
end
