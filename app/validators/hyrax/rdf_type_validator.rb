module Hyrax
  class RdfTypeValidator < ActiveModel::Validator

    attr_reader :file_set

    def validate(record)
      @file_set = record
      raise RdfTypeNotAllowed unless invalid_rdf_types.empty?
      raise MissingRequiredRdfyType unless required_but_missing_rdf_types.empty?
      raise DuplicateRdfTypeNotAllowed unless unallowed_duplicate_rdf_types.empty?
    end

    # TODO: Are there better error classes from AF (or elsewhere) to use/extend here?
    # TODO: Add informative error messages, complete with helpful suggestions.
    # TODO: Ok to namespace these error under Hydra::Works::PcdmUseValidator class?
    class RdfTypeNotAllowed < StandardError; end
    class MissingRequiredRdfyType < StandardError; end
    class DuplicateRdfTypeNotAllowed < StandardError; end

    # Returns the first config file found among the optional locations.
    def self.config_file_path
      @config_file_path ||= default_config_file_paths.find { |p| File.file?(p) }
    end

    # Sets the path to the config file.
    def self.config_file_path=(config_file_path)
      raise ConfigFileNotFound unless File.file?(config_file_path)
      @config_file_path = config_file_path
    end

    # Returns a list of optional locations for the config file, ordered
    # from most specific, to most generic.
    # TODO: Is this an intuitive convention for the config file name and location?
    def self.default_config_file_paths
      [
        # Check for config file first in the host app's root.
        "#{Rails.root}/config/rdf_type_validation.yml",

        # Next, use the default config file that ships with Hyrax
        "#{Hyrax::Engine.config.paths.path}/config/rdf_type_validation.yml"
      ]
    end

    private

      # Returns a list of rdf:type values from the file set's files that
      # aren't in the list of allowed values for rdf:type.
      def invalid_rdf_types
        rdf_types - allowed_rdf_types
      end

      # Returns a list of rdf:type values that are required, but missing from
      # the file set's files.
      def required_but_missing_rdf_types
        required_rdf_types - rdf_types
      end

      # Return a list of rdf:type values that are specified as required in the
      # config.
      def required_rdf_types
        binding.pry
        config.select { |rule| rule[:required] }.map{ |rule| rule[:rdf_type] }
      end

      # Returns a list of all rdf:type values from the file set's files that
      # exist more than once, but are not allowed to exist more than once.
      def unallowed_duplicate_rdf_types
        duplicate_rdf_types - rdf_types_limited_to_one
      end

      # Returns a list of rdf:type values from the file set's files that occur
      # more than once.
      def duplicate_rdf_types
        count = Hash.new 0
        rdf_types.each { |rdf_type| count[rdf_type] += 1 }
        count.keys
      end

      # Returns a list of rdf:types that are limited to one according to the
      # config.
      def rdf_types_limited_to_one
        config.select do |validation_rule|
          !validation_rule[:multiple]
        end
      end

      # Returns a list of all pdcm:use values from the file set's files.
      def rdf_types
        Array(file_set.files.map(&:type))
      end

      # Returns a list of allowed pdcm:use values.
      def allowed_rdf_types
        config
      end

      # Returns a config hash parsed from a YAML file.
      # This requires I/O, so it's memoized
      def config
        @config ||= begin
          config = YAML.safe_load(File.read(self.class.config_file_path))
          config.map! { |rule| HashWithIndifferentAccess.new(rule) }
        end
      end
  end
end
