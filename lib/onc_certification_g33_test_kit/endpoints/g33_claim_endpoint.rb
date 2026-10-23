require 'davinci_pas_test_kit/client/endpoints/claim_endpoint'
require_relative '../g33_options'
require_relative '../g33_pas_import'

module ONCCertificationG33TestKit
  class G33ClaimEndpoint < DaVinciPASTestKit::ClaimEndpoint
    # The parent derives this from the request path and keeps only the first segment after
    # /custom/, which drops this suite's version prefix. Everything the parent builds from
    # suite_id -- base_url, the Subscription reference in generated notifications, and the
    # suite id handed to SendPASSubscriptionNotification -- has to carry the prefix. The v2.2.1
    # pended scenario suppresses notifications here and sends them from a test instead, which gets
    # the prefixed suite id from G33ClientURLs.
    def suite_id
      G33PASImport.prefixed_suite_id
    end

    def ig_version
      G33Options::PAS_V221_DOTTED
    end
  end
end
