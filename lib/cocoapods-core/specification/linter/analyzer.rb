require 'cocoapods-core/specification/linter/result'

module Pod
  class Specification
    class Linter
      class Analyzer
        def initialize(consumer, results)
          @consumer = consumer
          @results = results
          @results.consumer = @consumer
        end

        # Analyzes the consumer adding a {Result} for any failed check to
        # the {#results} object.
        #
        # @return [Results] the results of the analysis.
        #
        def analyze
          validate_file_patterns
          check_tmp_arc_not_nil
          check_if_spec_is_empty
          check_install_hooks
          @results
        end

        private

        attr_reader :consumer

        attr_reader :results

        # Checks the attributes that represent file patterns.
        #
        # @todo Check the attributes hash directly.
        #
        def validate_file_patterns
          attributes = DSL.attributes.values.select(&:file_patterns?)
          attributes.each do |attrb|
            patterns = consumer.send(attrb.name)
            if patterns.is_a?(Hash)
              patterns = patterns.values.flatten(1)
            end
            patterns.each do |pattern|
              if pattern.start_with?('/')
                @results.error '[File Patterns] File patterns must be' \
                ' relative' \
                "and cannot start with a slash (#{attrb.name})."
              end
            end
          end
        end

        # @todo remove after the switch to true
        #
        def check_tmp_arc_not_nil
          spec = consumer.spec
          declared = false
          loop do
            declared = true unless spec.attributes_hash['requires_arc'].nil?
            declared = true unless spec.attributes_hash[consumer.platform_name.to_s].nil?
            spec = spec.parent
            break unless spec
          end

          unless declared
            @results.warning '[requires_arc] A value for `requires_arc`' \
            ' should be' \
            ' specified until the ' \
            'migration to a `true` default.'
          end
        end

        # Check empty subspec attributes
        #
        def check_if_spec_is_empty
          methods = %w( source_files resources resource_bundles preserve_paths dependencies
                        vendored_libraries vendored_frameworks )
          empty_patterns = methods.all? { |m| consumer.send(m).empty? }
          empty = empty_patterns && consumer.spec.subspecs.empty?
          if empty
            @results.error "[File Patterns] The #{consumer.spec} spec is empty"
            ' (no source files, ' \
            'resources, resource_bundles, preserve paths,' \
            'vendored_libraries, vendored_frameworks dependencies' \
            'or subspecs).'
          end
        end

        # Check the hooks
        #
        def check_install_hooks
          unless consumer.spec.pre_install_callback.nil?
            @results.warning '[pre_install_hook] The pre install hook has ' \
            'been deprecated, ' \
            'use the `resource_bundles` or the  `prepare_command` attributes.'
          end

          unless consumer.spec.post_install_callback.nil?
            @results.warning '[post_install_hook] The post install hook has ' \
            'been deprecated, ' \
            'use the `resource_bundles` or the  `prepare_command` attributes.'
          end
        end
      end
    end
  end
end
