require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Specification::Linter::Analyzer do

    describe 'File patterns & Build settings' do
      before do
        fixture_path = 'spec-repos/test_repo/Specs/BananaLib/1.0/BananaLib.podspec'
        podspec_path = fixture(fixture_path)
        linter = Specification::Linter.new(podspec_path)
        @spec = linter.spec
        @subject = Specification::Linter::Analyzer.new(@spec.consumer(:ios),
                                                       Specification::Linter::Results.new)
      end

      #----------------------------------------#

      describe 'File Patterns' do
        it 'checks if any file patterns is absolute' do
          @spec.source_files = '/Classes'
          results = @subject.analyze
          results.results.count.should.be.equal(1)
          expected = 'patterns must be relative'
          results.results.first.message.should.include?(expected)
          results.results.first.message.should.include?('File Patterns')
        end

        it 'checks if a specification is empty' do
          consumer = Specification::Consumer
          consumer.any_instance.stubs(:source_files).returns([])
          consumer.any_instance.stubs(:resources).returns({})
          consumer.any_instance.stubs(:resource_bundles).returns([])
          consumer.any_instance.stubs(:preserve_paths).returns([])
          consumer.any_instance.stubs(:subspecs).returns([])
          consumer.any_instance.stubs(:dependencies).returns([])
          consumer.any_instance.stubs(:vendored_libraries).returns([])
          consumer.any_instance.stubs(:vendored_frameworks).returns([])

          results = @subject.analyze
          results.results.count.should.be.equal(1)
          results.results.first.message.should.include?('spec is empty')
          results.results.first.message.should.include?('File Patterns')
        end
      end

      #----------------------------------------#

      describe 'Requires ARC' do
        it 'that the attribute is not nil' do
          @spec.requires_arc = nil
          results = @subject.analyze
          results.results.count.should.be.equal(1)
          expected = '`requires_arc` should be specified'
          results.results.first.message.should.include?(expected)
          results.results.first.message.should.include?('requires_arc')
        end

        it 'supports the declaration of the attribute per platform' do
          @spec.ios.requires_arc = true
          results = @subject.analyze
          results.results.should.be.empty?
        end

        it 'supports the declaration of the attribute in the parent' do
          @spec = Spec.new do |s|
            s.requires_arc = true
            s.subspec 'SubSpec' do |sp|
            end
          end
          consumer = @spec.consumer(:ios)
          @subject = Specification::Linter::Analyzer.new(consumer,
                                                         Specification::Linter::Results.new)
          results = @subject.analyze
          results.results.should.be.empty?
        end
      end

      #----------------------------------------#

      describe 'Hooks' do
        it 'checks if the pre install hook has been defined' do
          @spec.pre_install {}
          results = @subject.analyze
          results.results.count.should.be.equal(1)
          expected = 'pre install hook has been deprecated'
          results.results.first.message.should.include?(expected)
          results.results.first.message.should.include?('pre_install_hook')
        end

        it 'checks if the post install hook has been defined' do
          @spec.post_install {}
          results = @subject.analyze
          results.results.count.should.be.equal(1)
          expected = 'post install hook has been deprecated'
          results.results.first.message.should.include?(expected)
          results.results.first.message.should.include?('post_install_hook')
        end
      end
    end
  end
end
