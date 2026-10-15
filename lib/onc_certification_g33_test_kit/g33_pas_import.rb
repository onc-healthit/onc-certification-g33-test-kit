require 'davinci_pas_test_kit/client/v2.2.1/urls'
require_relative 'g33_options'

module ONCCertificationG33TestKit
  module G33ClientURLs
    SUITE_ID = 'g33_certification'.freeze

    def base_url
      @base_url ||= G33PASImport.base_url
    end
  end

  module G33PASImport
    RUNNABLE_TEXT_FIELDS = [:title, :short_title, :description, :input_instructions].freeze
    INPUT_TEXT_FIELDS = [:title, :description].freeze

    # Singular references only: statements about "PAS clients" in general are left as is.
    PAS_CLIENT_PATTERN = /PAS client(?!s)/
    HEALTH_IT_MODULE = 'Health IT Module'.freeze

    def self.import!(runnable)
      exclude_optional!(runnable)
      rewrite_pas_urls!(runnable)

      runnable
    end

    def self.exclude_optional!(runnable)
      runnable.all_children.reject(&:required?).each(&:remove_self_from_repository)
      runnable.all_children.select!(&:required?)

      runnable.all_children.each { |child| exclude_optional!(child) }
    end

    def self.rewrite_pas_urls!(runnable)
      runnable.include(G33ClientURLs) if runnable.include?(DaVinciPASTestKit::DaVinciPASV221::URLs)
      rewrite_runnable_text!(runnable)
      rewrite_input_descriptions!(runnable)
      rewrite_endpoint_suite_id!(runnable)

      runnable.all_children.each { |child| rewrite_pas_urls!(child) }
    end

    def self.rewrite_endpoint_suite_id!(runnable)
      return unless runnable.config.options[:endpoint_suite_id].to_s ==
                    DaVinciPASTestKit::DaVinciPASV221::ClientSuite.id.to_s

      runnable.config(options: { endpoint_suite_id: prefixed_suite_id })
    end
    private_class_method :rewrite_endpoint_suite_id!

    def self.rewrite_runnable_text!(runnable)
      RUNNABLE_TEXT_FIELDS.each do |field|
        text = runnable.send(field)
        next if text.nil?

        rewritten = rewrite_text(text)
        runnable.send(field, rewritten) unless rewritten == text
      end
    end
    private_class_method :rewrite_runnable_text!

    def self.rewrite_input_descriptions!(runnable)
      updates = runnable.config.inputs.each_with_object({}) do |(identifier, input), acc|
        input_updates = INPUT_TEXT_FIELDS.each_with_object({}) do |field, field_acc|
          text = input.send(field)
          next if text.nil?

          rewritten = rewrite_text(text)
          field_acc[field] = rewritten unless rewritten == text
        end

        acc[identifier] = input_updates if input_updates.any?
      end

      runnable.config(inputs: updates) if updates.any?
    end
    private_class_method :rewrite_input_descriptions!

    def self.rewrite_text(text)
      text.to_s.gsub(pas_base_url, base_url).gsub(PAS_CLIENT_PATTERN, HEALTH_IT_MODULE)
    end

    # The suite id as it appears in endpoint paths, including the PAS version prefix
    def self.prefixed_suite_id
      "#{G33ClientURLs::SUITE_ID}#{G33Options::PAS_V221_PREFIX}"
    end

    # Includes the PAS version prefix, so imported tests point at this suite's v2.2.1 endpoints
    def self.base_url
      "#{Inferno::Application['base_url']}/custom/#{prefixed_suite_id}"
    end

    def self.pas_base_url
      "#{Inferno::Application['base_url']}/custom/#{DaVinciPASTestKit::DaVinciPASV221::ClientSuite.id}"
    end
  end
end
