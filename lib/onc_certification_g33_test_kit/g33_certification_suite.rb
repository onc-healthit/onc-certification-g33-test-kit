require 'davinci_pas_test_kit'
require 'smart_app_launch_test_kit' # added this requirement to test backend services
require_relative 'metadata'
require_relative 'g33_options'
require_relative 'g33_pas_import'
require_relative 'g33_requirements'
require_relative 'attestations/rest_hook_documentation_attestation_test'
require_relative 'endpoints/g33_claim_endpoint'

module ONCCertificationG33TestKit
  class G33CertificationSuite < Inferno::TestSuite
    id :g33_certification
    title 'ONC Certification (g)(33) Prior Authorization Support API'
    short_title '(g)(33) PAS API'
    description %(
      The ONC Certification (g)(33) Prior Authorization Support API Test Suite is a testing tool
      for Health Level 7 (HL7®) Fast Healthcare Interoperability Resources
      (FHIR®) clients seeking to meet the requirements of the
      [prior authorization submission criterion § 170.315(g)(33)](https://healthit.gov/test-method/provider-prior-authorization-api-prior-authorization-support)
      in the ONC Certification Program.

      **DISCLAIMER**: this test kit is currently a draft and not ready for ONC certification purposes.

      This test suite is organized into groups that in sum cover the
      requirements within the [§ 170.315(g)(33) certification
      criterion](https://healthit.gov/test-method/provider-prior-authorization-api-prior-authorization-support).
      The groups are intended to be run in order during certification testing, but can
      be run out of order to support testing during development or certification
      preparation. Some groups depend on data collected during previous
      groups to function. In these cases, the group description describes
      these dependencies.

      Additional details about executing the tests in this suite can be found in
      the [walkthrough](https://github.com/onc-healthit/onc-certification-g33-test-kit/wiki/Walkthrough)
      which describes how to execute these tests against a client system.

      To get started, configure the client under test to submit prior authorization
      requests to Inferno's simulated PAS server using the following endpoints and
      begin with the "Client Registration" group:

      * FHIR Base URL: `#{G33PASImport.base_url}#{DaVinciPASTestKit::FHIR_PATH}`
      * Token Endpoint: `#{G33PASImport.base_url}#{SMARTAppLaunch::TOKEN_PATH}`

      Systems must pass all tests to qualify for ONC certification.
    )

    suite_summary %(
      The ONC Certification (g)(33) Prior Authorization Support API Test Kit is a testing tool
      for Health Level 7 (HL7®) Fast Healthcare Interoperability Resources
      (FHIR®) clients seeking to meet the requirements of the prior
      authorization submission criterion § 170.315(g)(33) in the ONC
      Certification Program.
    )

    links [
      {
        label: 'Report Issue',
        url: 'https://github.com/onc-healthit/onc-certification-g33-test-kit/issues/'
      },
      {
        label: 'Open Source',
        url: 'https://github.com/onc-healthit/onc-certification-g33-test-kit/'
      },
      {
        label: 'Download',
        url: 'https://github.com/onc-healthit/onc-certification-g33-test-kit/releases'
      },
      {
        label: 'Certification Criterion',
        url: 'https://healthit.gov/test-method/provider-prior-authorization-api-prior-authorization-support'
      }
    ]

    suite_option :pas_version,
                 title: 'PAS Version',
                 list_options: [
                   {
                     label: 'Da Vinci PAS v2.2.1',
                     value: G33Options::PAS_VERSION_2_2_1
                   }
                 ]

    suite_option :client_type,
                 title: 'Client Security Type',
                 list_options: [
                   {
                     label: 'SMART Backend Services',
                     value: G33Options::CLIENT_TYPE
                   }
                 ]

    requirement_sets(
      {
        identifier: G33Requirements::G33_SET,
        title: 'ONC Certification Criterion § 170.315(g)(33) Provider prior authorization API—' \
               'prior authorization support',
        actor: 'Provider'
      },
      {
        identifier: G33Requirements::J21_SET,
        title: 'ONC Certification Criterion § 170.315(j)(21) Subscriptions—client',
        actor: 'Client'
      },
      {
        identifier: "hl7.fhir.us.davinci-pas_#{G33Options::PAS_V221}",
        title: "Da Vinci Prior Authorization Support (PAS) v#{G33Options::PAS_V221}",
        actor: 'PAS Client'
      },
      {
        identifier: 'hl7.fhir.uv.subscriptions_1.1.0',
        title: 'Subscriptions R5 Backport IG',
        actor: 'Client'
      }
    )

    fhir_resource_validator do
      igs(G33Options::PAS_V221_IG_PACKAGE, G33Options::US_CORE_IG_PACKAGE)

      validation_context do
        txServer ENV.fetch('G33_TERMINOLOGY_SERVER', 'https://tx.fhir.org/r4')
        displayWarnings false
      end

      exclude_message do |message|
        # Messages expected of the form `<ResourceType>: <FHIRPath>: <message>`
        # We strip `<ResourceType>: <FHIRPath>: ` for the sake of matching
        DaVinciPASTestKit::V221_SUPPRESSED_MESSAGES.match?(message.message.sub(/\A\S+: \S+: /, ''))
      end
    end

    # The PAS IG version lives in a path prefix rather than in the suite id, so this stays a single
    # suite as more versions are added
    PAS_V221_PREFIX = G33Options::PAS_V221_PREFIX

    TOKEN_PATH = (PAS_V221_PREFIX + UDAPSecurityTestKit::TOKEN_PATH).freeze

    PAS_ENDPOINT_PATHS = [
      DaVinciPASTestKit::FHIR_METADATA_PATH,
      DaVinciPASTestKit::SESSION_FHIR_METADATA_PATH,
      DaVinciPASTestKit::SUBMIT_PATH,
      DaVinciPASTestKit::SESSION_SUBMIT_PATH,
      DaVinciPASTestKit::INQUIRE_PATH,
      DaVinciPASTestKit::SESSION_INQUIRE_PATH,
      DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH,
      DaVinciPASTestKit::SESSION_FHIR_SUBSCRIPTION_PATH,
      DaVinciPASTestKit::FHIR_SUBSCRIPTION_INSTANCE_PATH,
      DaVinciPASTestKit::SESSION_FHIR_SUBSCRIPTION_INSTANCE_PATH,
      DaVinciPASTestKit::FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH,
      DaVinciPASTestKit::SESSION_FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH,
      DaVinciPASTestKit::FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH,
      DaVinciPASTestKit::SESSION_FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH
    ].freeze

    # smart_server_metadata builds its urls by interpolating whatever it is given into
    # /custom/<id><path>, so it is given the prefixed suite id rather than the bare one,
    # prefixed urls are the only ones accepted and actually served by this suite
    route(:get, PAS_V221_PREFIX + SMARTAppLaunch::SMART_DISCOVERY_PATH, lambda { |_env|
      SMARTAppLaunch::MockSMARTServer.smart_server_metadata(G33PASImport.prefixed_suite_id)
    })

    route(:get, PAS_V221_PREFIX + DaVinciPASTestKit::FHIR_METADATA_PATH, lambda { |env|
      DaVinciPASTestKit::MockPASServer.capability_statement_response(env)
    })
    route(:get, PAS_V221_PREFIX + DaVinciPASTestKit::SESSION_FHIR_METADATA_PATH, lambda { |env|
      DaVinciPASTestKit::MockPASServer.capability_statement_response(env)
    })

    # Only the prefixed token path is served, so that the two ways a client can learn this url
    # (fetching the discovery document above, or being handed it by the registration test) give the
    # same answer, and that answer is the one the verification test accepts in the `aud` claim.
    # Serving an unprefixed path would let a misconfigured client get a token and then
    # fail verification.
    suite_endpoint :post, TOKEN_PATH, DaVinciPASTestKit::MockUdapSmartServer::TokenEndpoint

    suite_endpoint :post, PAS_V221_PREFIX + DaVinciPASTestKit::SUBMIT_PATH, G33ClaimEndpoint
    suite_endpoint :post, PAS_V221_PREFIX + DaVinciPASTestKit::SESSION_SUBMIT_PATH, G33ClaimEndpoint
    suite_endpoint :post, PAS_V221_PREFIX + DaVinciPASTestKit::INQUIRE_PATH, G33ClaimEndpoint
    suite_endpoint :post, PAS_V221_PREFIX + DaVinciPASTestKit::SESSION_INQUIRE_PATH, G33ClaimEndpoint
    suite_endpoint :post, PAS_V221_PREFIX + DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH,
                   DaVinciPASTestKit::SubscriptionCreateEndpoint
    suite_endpoint :post, PAS_V221_PREFIX + DaVinciPASTestKit::SESSION_FHIR_SUBSCRIPTION_PATH,
                   DaVinciPASTestKit::SubscriptionCreateEndpoint
    suite_endpoint :get, PAS_V221_PREFIX + DaVinciPASTestKit::FHIR_SUBSCRIPTION_INSTANCE_PATH,
                   SubscriptionsTestKit::SubscriptionReadEndpoint
    suite_endpoint :get, PAS_V221_PREFIX + DaVinciPASTestKit::SESSION_FHIR_SUBSCRIPTION_INSTANCE_PATH,
                   SubscriptionsTestKit::SubscriptionReadEndpoint
    suite_endpoint :post, PAS_V221_PREFIX + DaVinciPASTestKit::FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH,
                   DaVinciPASTestKit::SubscriptionStatusEndpoint
    suite_endpoint :post, PAS_V221_PREFIX + DaVinciPASTestKit::SESSION_FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH,
                   DaVinciPASTestKit::SubscriptionStatusEndpoint
    suite_endpoint :get, PAS_V221_PREFIX + DaVinciPASTestKit::FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH,
                   DaVinciPASTestKit::SubscriptionStatusEndpoint
    suite_endpoint :get, PAS_V221_PREFIX + DaVinciPASTestKit::SESSION_FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH,
                   DaVinciPASTestKit::SubscriptionStatusEndpoint
    suite_endpoint :post, PAS_V221_PREFIX + DaVinciPASTestKit::FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH,
                   DaVinciPASTestKit::SubscriptionStatusEndpoint
    suite_endpoint :post, PAS_V221_PREFIX + DaVinciPASTestKit::SESSION_FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH,
                   DaVinciPASTestKit::SubscriptionStatusEndpoint

    allow_cors(TOKEN_PATH, PAS_V221_PREFIX + SMARTAppLaunch::SMART_DISCOVERY_PATH,
               *PAS_ENDPOINT_PATHS.map { |path| PAS_V221_PREFIX + path })

    def self.extract_token_from_query_params(request)
      request.query_parameters['token']
    end

    resume_test_route :get, PAS_V221_PREFIX + DaVinciPASTestKit::RESUME_PASS_PATH do |request|
      G33CertificationSuite.extract_token_from_query_params(request)
    end
    resume_test_route :get, PAS_V221_PREFIX + DaVinciPASTestKit::RESUME_FAIL_PATH, result: 'fail' do |request|
      G33CertificationSuite.extract_token_from_query_params(request)
    end

    # SMART Backend Services is the only authentication approach used
    CLIENT_ID_REQUIERED = { inputs: { client_id: { optional: false } } }.freeze

    # Imports a group from the PAS v2.2.1 client suite and tags it with that version, so the
    # :pas_version suite option selects between versions rather than showing every version's groups
    # at once.
    def self.import_v221!(runnable)
      G33PASImport.import!(runnable)
      runnable.required_suite_options(G33Options::PAS_V221_REQUIREMENT)
      runnable
    end

    import_v221!(
      group(from: :pas_client_v221_registration, id: :g33_pas_client_v221_registration) do
        DaVinciPASTestKit::PASClientOptions.recursive_remove_input(self, :session_url_path)
        config({ inputs: { client_id: { optional: true } } })
      end
    )

    import_v221!(
      group(from: :pas_client_v221_subscription_setup, id: :g33_pas_client_v221_subscription_setup) do
        DaVinciPASTestKit::PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(CLIENT_ID_REQUIERED)
      end
    )

    import_v221!(
      group(from: :pas_client_v221_workflows, id: :g33_pas_client_v221_workflows) do
        DaVinciPASTestKit::PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(CLIENT_ID_REQUIERED)
      end
    )

    import_v221!(
      group(from: :pas_client_v221_must_support, id: :g33_pas_client_v221_must_support) do
        DaVinciPASTestKit::PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(CLIENT_ID_REQUIERED)
      end
    )

    import_v221!(
      group(from: :pas_client_v221_error_handling_group, id: :g33_pas_client_v221_error_handling) do
        DaVinciPASTestKit::PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(CLIENT_ID_REQUIERED)
      end
    )

    import_v221!(group(from: :pas_client_v221_auth_smart, id: :g33_pas_client_v221_auth_smart))

    import_v221!(
      group(from: :pas_client_v221_attestations, id: :g33_pas_client_v221_attestations) do
        # The imported description speaks only of the PAS IG, but the attestation added below
        # covers a certification requirement instead
        description "#{description}\n\nOne test in this group attests to a requirement of the " \
                    '§ 170.315(g)(33) certification criterion rather than of the PAS IG.'

        # (g)(33)(ii) is a documentation requirement that neither the PAS client suite nor the
        # Subscriptions test kit defines an attestation for, so this suite adds its own
        test from: :g33_rest_hook_documentation_attestation
      end
    )

    # Adds the (g)(33) and (j)(21) certification requirements to the imported runnables that verify
    # them, after every group has been imported.
    G33Requirements.apply!(self)
  end
end
