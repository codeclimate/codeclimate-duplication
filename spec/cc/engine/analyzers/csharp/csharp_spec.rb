require "spec_helper"
require "cc/engine/analyzers/csharp/main"
require "cc/engine/analyzers/engine_config"

module CC::Engine::Analyzers
  RSpec.describe Csharp::Main, in_tmpdir: true do
    include AnalyzerSpecHelpers

    describe "#run" do
      let(:engine_conf) { EngineConfig.new({}) }

      it "prints an issue for similar code" do
        create_source_file("foo.cs", <<-EOCSHARP)
        class ArrayDemo
        {
            void Foo()
            {
                int[] anArray = new int[10];

                foreach (int i in new int[] { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 })
                {
                    anArray[i] = i;
                }

                foreach (int i in anArray)
                {
                    Console.WriteLine(i);
                }

                Console.WriteLine("");
            }

            void Bar()
            {
                int[] anArray = new int[10];

                foreach (int i in new int[] { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 })
                {
                    anArray[i] = i;
                }

                foreach (int i in anArray)
                {
                    Console.WriteLine(i);
                }

                Console.WriteLine("");
            }
        }
        EOCSHARP

        issues = run_engine(engine_conf).strip.split("\0")
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("similar-code")
        expect(json["description"]).to eq("Similar blocks of code found in 2 locations. Consider refactoring.")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.cs",
          "lines" => { "begin" => 3, "end" => 18 },
        })
        expect(json["other_locations"]).to eq([
          {"path" => "foo.cs", "lines" => { "begin" => 20, "end" => 35 } },
        ])
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
      end

      it "ignores using declarations" do
        create_source_file("foo.cs", <<-EOF)
        using System;
        EOF

        create_source_file("bar.cs", <<-EOF)
        using System;
        EOF

        issues = run_engine(engine_conf).strip.split("\0")
        expect(issues).to be_empty
      end

      it "prints an issue for similar code when the only difference is the value of a literal" do
        create_source_file("foo.cs", <<-EOCSHARP)
        class ArrayDemo
        {
            void Foo()
            {
                var scott = new int[] {
                    0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F
                };

                var anArray = new int[10];

                for (int i = 0; i < 10; i++)
                {
                    anArray[i] = i;
                }

                foreach (i in anArray)
                {
                    Console.WriteLine(i + " ");
                }

                Console.WriteLine();
            }

            void Bar()
            {
                var scott = new int[] {
                    0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7
                };

                var anArray = new int[10];

                for (int i = 0; i < 10; i++)
                {
                    anArray[i] = i;
                }

                foreach (i in anArray)
                {
                    Console.WriteLine(i + " ");
                }

                Console.WriteLine();
            }
          }
        EOCSHARP

        issues = run_engine(engine_conf).strip.split("\0")
        expect(issues.length).to be > 0
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("similar-code")

        expect(json["description"]).to eq("Similar blocks of code found in 2 locations. Consider refactoring.")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.cs",
          "lines" => { "begin" => 3, "end" => 22 },
        })
        expect(json["other_locations"]).to eq([
          {"path" => "foo.cs", "lines" => { "begin" => 24, "end" => 43 } },
        ])
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
      end

      it "ignores comment docs and comments" do
        create_source_file("foo.cs", <<-EOCSHARP)
        /********************************************************************
         *  A comment!
         *******************************************************************/

        using System;

        class Foo
        {
            void Bar()
            {
                Console.WriteLine("Hello");
            }
        }
        EOCSHARP

        create_source_file("bar.cs", <<-EOCSHARP)
        /********************************************************************
         *  A comment!
         *******************************************************************/

        using System;

        class Bar
        {
            void Baz()
            {
                Console.WriteLine("Qux");
            }
        }
        EOCSHARP

        issues = run_engine(engine_conf).strip.split("\0")
        expect(issues).to be_empty
      end

    end
  end
end
