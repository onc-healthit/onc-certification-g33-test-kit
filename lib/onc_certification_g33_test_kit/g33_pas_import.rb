require 'davinci_pas_test_kit/client/v2.2.1/urls'
require_relative 'g33_options'

module ONCCertificationG33TestKit
  module G33ClientURLs
    SUITE_ID = 'g33_certification'.freeze

    def base_url
      @base_url ||= G33PASImport.base_url
    end

    # Tests that send notifications themselves, such as the pended notification test, hand this to the
    # notification job, which builds the Subscription urls in the notification from it
    def suite_id
      G33PASImport.prefixed_suite_id
    end
  end

  module G33PASImport
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
      [:description, :input_instructions].each do |field|
        text = runnable.send(field).to_s
        next unless text.include?(pas_base_url)

        runnable.send(field, text.gsub(pas_base_url, base_url))
      end
    end
    private_class_method :rewrite_runnable_text!

    def self.rewrite_input_descriptions!(runnable)
      updates = runnable.config.inputs.each_with_object({}) do |(identifier, input), acc|
        description = input.description.to_s
        next unless description.include?(pas_base_url)

        acc[identifier] = { description: description.gsub(pas_base_url, base_url) }
      end

      runnable.config(inputs: updates) if updates.any?
    end
    private_class_method :rewrite_input_descriptions!

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
