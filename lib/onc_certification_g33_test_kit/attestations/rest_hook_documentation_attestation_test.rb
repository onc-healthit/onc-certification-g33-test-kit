require 'davinci_pas_test_kit/client/v2.2.1/attestations/attestation_instructions'
require_relative '../g33_requirements'

module ONCCertificationG33TestKit
  # § 170.315(g)(33)(ii) is a documentation requirement on the client's REST-Hook notification
  # endpoint, which no test in the PAS client or Subscriptions test kits demonstrates, so it is
  # attested to here.
  class RestHookDocumentationAttestationTest < Inferno::Test
    id :g33_rest_hook_documentation_attestation
    ATTESTATION_TITLE = 'Subscriptions client endpoint capabilities for the "REST-Hook" channel include ' \
                        'complete accompanying technical documentation'.freeze
    title ATTESTATION_TITLE
    description %(
      During this test, the tester will confirm that the supported subscriptions client endpoint
      capabilities for the "REST-Hook" channel are accompanied by complete technical documentation.
      To see the specifics of the attested requirements, click the "View Specification Requirements" link for this
      test.
    )
    attestation
    # Declared here rather than in G33Requirements::REQUIREMENT_MAP, which tags runnables imported
    # from the PAS client suite
    verifies_requirements "#{G33Requirements::G33_SET}@9"
    input_instructions DaVinciPASTestKit::DaVinciPASV221::ATTESTATION_INPUT_INSTRUCTIONS

    input :rest_hook_documentation_attestation,
          title: ATTESTATION_TITLE,
          description: %(
            I attest that the supported subscriptions client endpoint capabilities for the
            "REST-Hook" channel include complete accompanying technical documentation.
          ),
          type: 'radio',
          default: 'false',
          options: {
            list_options: [
              { label: 'Yes', value: 'true' },
              { label: 'No', value: 'false' }
            ]
          }
    input :rest_hook_documentation_attestation_note,
          title: 'Notes, if applicable:',
          type: 'textarea',
          optional: true

    run do
      assert rest_hook_documentation_attestation == 'true'
    end
  end
end
