require 'cocoapods-core/specification/linter/result'

module Pod
  class Specification
    class Linter
      class Analyzer

        include Linter::ResultHelpers

        def initialize(consumer)
          @consumer = consumer
          @results = []
        end

        def analyze
          check_for_unknown_keys
          validate_file_patterns
          check_tmp_arc_not_nil
          check_if_spec_is_empty
          check_install_hooks
        end

        private

        attr_reader :consumer

        # Checks the attributes hash for any unknown key which might be the
        # result of a misspell in JSON file.
        #
        # @note Sub-keys are not checked per-platform as
        #       there is no attribute supporting this combination.
        #
        # @note The keys of sub-keys are not checked as they are only used by 
        #       the `source` attribute and they are subject
        #       to change according the support in the
        #       `cocoapods-downloader` gem.
        #
        def check_for_unknown_keys
          Pod::Specification::DSL.attributes
          attributes_keys = Pod::Specification::DSL.attributes.keys.map(&:to_s)
          platform_keys = Specification::DSL::PLATFORMS.map(&:to_s)
          valid_keys = attributes_keys + platform_keys
          keys = consumer.spec.attributes_hash.keys
          unknown_keys = keys - valid_keys

          unknown_keys.each do |key|
            warning "Unrecognized `#{key}` key"
          end

         Pod::Specification::DSL.attributes.each do |key, attribute|
           if attribute.keys
             value = consumer.spec.attributes_hash[key.to_s]
             if value
               if attribute.keys.is_a?(Array)
                 unknown_keys = value.keys - attribute.keys.map(&:to_s)
                 unknown_keys.each do |key|
                   warning "Unrecognized `#{key}` key for " \
                     "`#{attribute.name}` attribute"
                 end
               end
             end
           end
         end
        end

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
                error "File patterns must be relative and cannot start with a " \
                "slash (#{attrb.name})."
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
            warning "A value for `requires_arc` should be specified until the " \
            "migration to a `true` default."
          end
        end

        # Check empty subspec attributes
        #
        def check_if_spec_is_empty
          methods = %w( source_files resources preserve_paths dependencies vendored_libraries vendored_frameworks )
          empty_patterns = methods.all? { |m| consumer.send(m).empty? }
          empty = empty_patterns && consumer.spec.subspecs.empty?
          if empty
            error "The #{consumer.spec} spec is empty (no source files, " \
            "resources, preserve paths, vendored_libraries, " \
              "vendored_frameworks dependencies or subspecs)."
          end
        end

        # Check the hooks
        #
        def check_install_hooks
          unless consumer.spec.pre_install_callback.nil?
            warning "The pre install hook has been deprecated, " \
            "use the `resource_bundles` or the  `prepare_command` attributes."
          end

          unless consumer.spec.post_install_callback.nil?
            warning "The post install hook has been deprecated, " \
            "use the `resource_bundles` or the  `prepare_command` attributes."
          end
        end
      end
    end
  end
end
