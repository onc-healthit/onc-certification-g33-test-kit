module ONCCertificationG33TestKit
  # Maps the § 170.315(g)(33) and § 170.315(j)(21) certification requirements onto the runnables
  # imported from the Da Vinci PAS client suite.
  #
  # The imported runnables already declare the IG-level requirements that they verify, so these
  # regulatory requirements are added to what each one declares rather than replacing it.
  #
  # Regulatory requirements are written at the level of a whole capability, so they are attached to
  # the group that exercises that capability when no single test demonstrates it, and to individual
  # tests when one does.
  module G33Requirements
    G33_SET = '170.315(g)(33)_HTI-4'.freeze
    J21_SET = '170.315(j)(21)_HTI-4'.freeze

    # Requirement id => the runnables that verify it, identified by the trailing portion of their id
    # within this suite. Keys are the shortest suffix that identifies a single runnable; ids that
    # are reused across groups (e.g. the response attestation) are qualified by their parent.
    REQUIREMENT_MAP = {
      # 170.315(g)(33): "[E]nable users to submit prior authorization requests"
      "#{G33_SET}@1" => [
        'g33_pas_client_v221_workflows'
      ],
      # 170.315(g)(33)(i): submit a prior authorization request as a client in accordance with PAS
      "#{G33_SET}@2" => [
        'g33_pas_client_v221_workflows',
        'g33_pas_client_v221_must_support'
      ],
      # 170.315(g)(33)(i)(A): "Support registration capabilities applicable to a client system."
      "#{G33_SET}@3" => [
        'g33_pas_client_v221_registration'
      ],
      # 170.315(g)(33)(i)(B): SMART Backend Services authentication and authorization
      "#{G33_SET}@4" => [
        'g33_pas_client_v221_registration-smart_client_registration_bsca_verification',
        'g33_pas_client_v221_auth_smart'
      ],
      # 170.315(g)(33)(i)(C): "Support the ability to submit a prior authorization request as a
      # client system"
      "#{G33_SET}@5" => [
        'g33_pas_client_v221_workflows'
      ],
      # 170.315(g)(33)(i)(C)(1): the "EHR PAS Capabilities" CapabilityStatement, which requires the
      # Claim $submit and $inquire operations and the Subscription create, update, and delete
      # interactions. Update and delete are not yet exercised - see 170.315(j)(21)@6 and @7.
      "#{G33_SET}@6" => [
        'g33_pas_client_v221_workflows',
        'pas_client_v221_subscription_create_test',
        'pas_client_v221_inquire_request_bundle_validation_test',
        'pas_client_v221_inquire_must_support'
      ],
      # 170.315(g)(33)(i)(C)(2): "Support the ability to consume and process a 'ClaimResponse.'"
      "#{G33_SET}@7" => [
        'pas_client_v221_submit_response_must_support-pas_client_v221_submit_response_must_support_claimresponse',
        'pas_client_v221_submit_response_must_support-pas_client_v221_response_attest'
      ],
      # 170.315(g)(33)(i)(C)(3): subscriptions per (j)(21), to support pended responses
      "#{G33_SET}@8" => [
        'g33_pas_client_v221_subscription_setup',
        'pas_client_v221_pended_group'
      ],
      # 170.315(g)(33)(ii) is a documentation requirement on the client's REST-Hook notification
      # endpoint. No imported runnable demonstrates it, so it is verified by this suite's own
      # RestHookDocumentationAttestationTest, which declares it directly.

      # 170.315(j)(21): subscriptions as a client per the Subscriptions R5 Backport IG
      "#{J21_SET}@1" => [
        'g33_pas_client_v221_subscription_setup',
        'pas_client_v221_pended_group'
      ],
      # 170.315(j)(21)(i): the "Topic-Based Subscriptions - FHIR R4" section
      "#{J21_SET}@2" => [
        'pas_client_subscription_pas_conformance_test',
        'subscriptions_r4_client_handshake_notification_verification',
        'subscriptions_r4_client_event_notification_verification'
      ],
      # 170.315(j)(21)(ii): the "R4/B Topic-Based Subscription" profile, which the PAS Subscription
      # profile validated by this test derives from
      "#{J21_SET}@3" => [
        'pas_client_subscription_pas_conformance_test'
      ],
      # 170.315(j)(21)(iii): client capabilities for the "R4 Topic-Based Subscription Server
      # Capability Statement". Only the create interaction is exercised - see @6 and @7.
      "#{J21_SET}@4" => [
        'pas_client_v221_subscription_create_test'
      ],
      # 170.315(j)(21)(iii): the Subscription "create" interaction
      "#{J21_SET}@5" => [
        'pas_client_v221_subscription_create_test'
      ],
      # 170.315(j)(21)(iii)@6 ("update") and @7 ("delete") are not verified: the Subscriptions
      # update and delete API tests are pending.

      # 170.315(j)(21)(iv): receive notifications per "Topic-Based Subscriptions - FHIR R4"
      "#{J21_SET}@8" => [
        'subscriptions_r4_client_handshake_notification_verification',
        'subscriptions_r4_client_event_notification_verification'
      ],
      # 170.315(j)(21)(iv): consume notifications via the "REST-Hook" channel
      "#{J21_SET}@9" => [
        'subscriptions_r4_client_handshake_notification_verification',
        'subscriptions_r4_client_event_notification_verification'
      ]
    }.freeze

    # Adds the requirements above to the runnables that verify them. Raises if a key no longer
    # identifies exactly one runnable, so that a change to the imported suite is caught here rather
    # than silently dropping coverage.
    def self.apply!(suite)
      runnables = [suite, *suite.all_descendants]

      REQUIREMENT_MAP.each do |requirement_id, runnable_keys|
        runnable_keys.each do |runnable_key|
          add_requirement!(find_runnable!(runnables, runnable_key), requirement_id)
        end
      end
    end

    def self.find_runnable!(runnables, runnable_key)
      matches = runnables.select { |runnable| runnable.id.to_s.end_with?("-#{runnable_key}") }

      raise "No runnable found for requirement mapping key '#{runnable_key}'" if matches.empty?

      if matches.length > 1
        raise "Requirement mapping key '#{runnable_key}' matches multiple runnables: " \
              "#{matches.map(&:id).join(', ')}"
      end

      matches.first
    end
    private_class_method :find_runnable!

    def self.add_requirement!(runnable, requirement_id)
      runnable.verifies_requirements(*(runnable.verifies_requirements + [requirement_id]).uniq)
    end
    private_class_method :add_requirement!
  end
end
