require "spec_helper"
require "cc/engine/analyzers/typescript/main"
require "cc/engine/analyzers/engine_config"
require "cc/engine/analyzers/file_list"

module CC::Engine::Analyzers
  RSpec.describe TypeScript::Main, in_tmpdir: true do
    include AnalyzerSpecHelpers

    describe "#run" do
      let(:engine_conf) { EngineConfig.new({}) }

      xit "prints an issue for similar code" do
        create_source_file("foo.ts", <<-EOF)
          function showMessage(message: IMessage, force?: boolean): void {
            this.message = message;

            dom.removeClass(this.element, 'idle');
            dom.removeClass(this.element, 'info');
            dom.removeClass(this.element, 'warning');
            dom.removeClass(this.element, 'error');
            dom.addClass(this.element, this.classForType(message.type));

            const styles = this.stylesForType(this.message.type);
            this.element.style.border = styles.border ? `1px solid ${styles.border}` : null;

            // ARIA Support
            let alertText: string;
            if (message.type === MessageType.ERROR) {
              alertText = nls.localize('alertErrorMessage', "Error: {0}", message.content);
            } else if (message.type === MessageType.WARNING) {
              alertText = nls.localize('alertWarningMessage', "Warning: {0}", message.content);
            } else {
              alertText = nls.localize('alertInfoMessage', "Info: {0}", message.content);
            }

            aria.alert(alertText);

            if (this.hasFocus() || force) {
              this._showMessage();
            }
          }

          function hideMessage(message: IMessage, force?: boolean): void {
            this.message = message;

            dom.removeClass(this.element, 'idle');
            dom.removeClass(this.element, 'info');
            dom.removeClass(this.element, 'warning');
            dom.removeClass(this.element, 'error');
            dom.addClass(this.element, this.classForType(message.type));

            const styles = this.stylesForType(this.message.type);
            this.element.style.border = styles.border ? `1px solid ${styles.border}` : null;

            // ARIA Support
            let alertText: string;
            if (message.type === MessageType.ERROR) {
              alertText = nls.localize('alertErrorMessage', "Error: {0}", message.content);
            } else if (message.type === MessageType.WARNING) {
              alertText = nls.localize('alertWarningMessage', "Warning: {0}", message.content);
            } else {
              alertText = nls.localize('alertInfoMessage', "Info: {0}", message.content);
            }

            aria.alert(alertText);

            if (this.hasFocus() || force) {
              this._showMessage();
            }
          }
        EOF

        issues = run_engine(engine_conf).strip.split("\0")
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("similar-code")
        expect(json["description"]).to eq("Similar blocks of code found in 2 locations. Consider refactoring.")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.ts",
          "lines" => { "begin" => 1, "end" => 28 },
        })
        expect(json["remediation_points"]).to eq(10_200_000)
        expect(json["other_locations"]).to eq([
          {"path" => "foo.ts", "lines" => { "begin" => 30, "end" => 32 } },
        ])
        expect(json["content"]["body"]).to match /This issue has a mass of 103/
        expect(json["fingerprint"]).to eq("48eb151dc29634f90a86ffabf9d3c4b5")
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
      end

      xit "prints an issue for identical code" do
        create_source_file("foo.ts", <<-EOF)
          function showMessage(message: IMessage, force?: boolean): void {
            this.message = message;

            dom.removeClass(this.element, 'idle');
            dom.removeClass(this.element, 'info');
            dom.removeClass(this.element, 'warning');
            dom.removeClass(this.element, 'error');
            dom.addClass(this.element, this.classForType(message.type));

            const styles = this.stylesForType(this.message.type);
            this.element.style.border = styles.border ? `1px solid ${styles.border}` : null;

            // ARIA Support
            let alertText: string;
            if (message.type === MessageType.ERROR) {
              alertText = nls.localize('alertErrorMessage', "Error: {0}", message.content);
            } else if (message.type === MessageType.WARNING) {
              alertText = nls.localize('alertWarningMessage', "Warning: {0}", message.content);
            } else {
              alertText = nls.localize('alertInfoMessage', "Info: {0}", message.content);
            }

            aria.alert(alertText);

            if (this.hasFocus() || force) {
              this._showMessage();
            }
          }

          function showMessage(message: IMessage, force?: boolean): void {
            this.message = message;

            dom.removeClass(this.element, 'idle');
            dom.removeClass(this.element, 'info');
            dom.removeClass(this.element, 'warning');
            dom.removeClass(this.element, 'error');
            dom.addClass(this.element, this.classForType(message.type));

            const styles = this.stylesForType(this.message.type);
            this.element.style.border = styles.border ? `1px solid ${styles.border}` : null;

            // ARIA Support
            let alertText: string;
            if (message.type === MessageType.ERROR) {
              alertText = nls.localize('alertErrorMessage', "Error: {0}", message.content);
            } else if (message.type === MessageType.WARNING) {
              alertText = nls.localize('alertWarningMessage', "Warning: {0}", message.content);
            } else {
              alertText = nls.localize('alertInfoMessage', "Info: {0}", message.content);
            }

            aria.alert(alertText);

            if (this.hasFocus() || force) {
              this._showMessage();
            }
          }
        EOF

        issues = run_engine(engine_conf).strip.split("\0")
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("identical-code")
        expect(json["description"]).to eq("Identical blocks of code found in 2 locations. Consider refactoring.")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.ts",
          "lines" => { "begin" => 2, "end" => 8 },
        })
        expect(json["remediation_points"]).to eq(420_000)
        expect(json["other_locations"]).to eq([
          {"path" => "foo.ts", "lines" => { "begin" => 10, "end" => 16 } },
        ])
        expect(json["content"]["body"]).to match /This issue has a mass of 52/
        expect(json["fingerprint"]).to eq("dbb957b34f7b5312538235c0aa3f52a0")
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MINOR)
      end

      it "outputs a warning for unprocessable errors" do
        create_source_file("foo.ts", <<-EOF)
          ---
        EOF

        expect(CC.logger).to receive(:warn).with(/Response status: 422/)
        expect(CC.logger).to receive(:warn).with(/Skipping/)
        run_engine(engine_conf)
      end
    end
  end
end
