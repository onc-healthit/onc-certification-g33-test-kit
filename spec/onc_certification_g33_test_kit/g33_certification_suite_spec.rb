RSpec.describe ONCCertificationG33TestKit::G33CertificationSuite do
  let(:suite) { Inferno::Repositories::TestSuites.new.find('g33_certification') }

  def all_runnables(runnable = suite, collected = [])
    collected << runnable
    runnable.all_children.each { |child| all_runnables(child, collected) }
    collected
  end

  def imported_pas_tests
    all_runnables.select do |runnable|
      runnable < Inferno::Test && runnable.include?(DaVinciPASTestKit::DaVinciPASV221::URLs)
    end
  end

  # Leaf tests reachable under the given suite option selection.
  def leaf_tests(runnable, selected_options = [], collected = [])
    runnable.children(selected_options).each do |child|
      if child < Inferno::TestGroup
        leaf_tests(child, selected_options, collected)
      else
        collected << child
      end
    end
    collected
  end

  # The trailing segment of a runnable id, which is stable across the re-parenting that importing
  # into this suite performs.
  def short_ids(tests)
    tests.map { |test| test.id.to_s.split('-').last }
  end

  # The PAS IG version lives in a path prefix rather than in the suite id, so that a later version
  # can be added to this same suite as another prefixed set of endpoints.
  describe 'suite identity' do
    it 'uses a version neutral suite id' do
      expect(suite.id).to eq('g33_certification')
      expect(ONCCertificationG33TestKit::G33ClientURLs::SUITE_ID).to eq(suite.id)
    end

    it 'is the id the test kit registers' do
      expect(ONCCertificationG33TestKit::Metadata.suite_ids).to include(suite.id.to_sym)
    end

    # The imported tests build their own urls, so they have to agree with where the endpoints are
    # actually registered.
    it 'builds test urls that match the prefix the endpoints are registered under' do
      expect(ONCCertificationG33TestKit::G33PASImport.base_url).to eq(
        "#{Inferno::Application['base_url']}/custom/#{suite.id}" \
        "#{ONCCertificationG33TestKit::G33Options::PAS_V221_PREFIX}"
      )
    end

    it 'serves the PAS endpoints under the version prefix' do
      paths = Inferno.routes.select { |route| route[:suite]&.id == suite.id }.map { |route| route[:path] }
      prefix = ONCCertificationG33TestKit::G33Options::PAS_V221_PREFIX

      expect(paths).to_not be_empty
      expect(paths.select { |path| path.start_with?(prefix) }).to_not be_empty
      expect(paths).to include("#{prefix}#{DaVinciPASTestKit::SUBMIT_PATH}")
      expect(paths).to include("#{prefix}#{DaVinciPASTestKit::INQUIRE_PATH}")
    end
  end

  describe 'backend services authentication' do
    it 'imports the SMART authentication review group' do
      expect(all_runnables.map(&:id)).to include(a_string_including('auth_smart'))
    end

    it 'removes the session_url_path input used only by the other authentication option' do
      with_input = all_runnables.select { |runnable| runnable.inputs.include?(:session_url_path) }

      expect(with_input.map(&:id)).to be_empty
    end

    it 'points the SMART verification tests at this suite rather than the PAS client suite' do
      configured = all_runnables.select { |runnable| runnable.config.options[:endpoint_suite_id].present? }
      values = configured.map { |runnable| runnable.config.options[:endpoint_suite_id].to_s }.uniq

      expect(configured).to_not be_empty
      expect(values).to eq([ONCCertificationG33TestKit::G33PASImport.prefixed_suite_id])
    end

    it 'checks the token url the registration test tells the tester to use' do
      test = all_runnables.find do |runnable|
        runnable.id.to_s.end_with?('smart_client_token_request_bsca_verification')
      end

      expect(test.new.client_token_url).to eq(
        "#{ONCCertificationG33TestKit::G33PASImport.base_url}#{SMARTAppLaunch::TOKEN_PATH}"
      )
    end

    # A client that discovers the token endpoint rather than being handed it must end up at the
    # same url, or it authenticates successfully and then fails the `aud` check in the token
    # request verification test.
    it 'advertises the same endpoints in discovery that the verification tests require' do
      discovery = Inferno.routes.find do |route|
        route[:suite]&.id == suite.id && route[:path].end_with?(SMARTAppLaunch::SMART_DISCOVERY_PATH)
      end
      _status, _headers, body = discovery[:handler].call({})
      metadata = JSON.parse(body.first)
      verification = all_runnables.find do |runnable|
        runnable.id.to_s.end_with?('smart_client_token_request_bsca_verification')
      end
      registration = all_runnables.find { |runnable| runnable.id.to_s.end_with?('reg_config_smart_display') }

      expect(metadata['token_endpoint']).to eq(verification.new.client_token_url)
      expect(metadata['token_endpoint']).to eq(registration.new.token_url)
      expect(metadata['issuer']).to eq(registration.new.fhir_base_url)
    end

    # Every route is version scoped, so a second PAS version can be added without colliding.
    it 'serves no endpoints outside the version prefix' do
      paths = Inferno.routes.select { |route| route[:suite]&.id == suite.id }.map { |route| route[:path] }

      expect(paths).to all(start_with(ONCCertificationG33TestKit::G33Options::PAS_V221_PREFIX))
    end
  end

  describe 'import completeness' do
    let(:pas_suite) { Inferno::Repositories::TestSuites.new.find('davinci_pas_client_suite_v221') }
    let(:smart_option) do
      [Inferno::DSL::SuiteOption.new(id: :client_type, value: ONCCertificationG33TestKit::G33Options::CLIENT_TYPE)]
    end
    let(:expected_ids) { short_ids(leaf_tests(pas_suite, smart_option).select(&:required?)) }
    let(:selected_options) do
      suite.suite_options.map do |option|
        Inferno::DSL::SuiteOption.new(id: option.id, value: option.list_options.first[:value])
      end
    end
    let(:imported_ids) { short_ids(leaf_tests(suite, selected_options)) }
    # Tests this suite defines itself, which cover requirements the PAS client suite has no test for
    let(:locally_defined_ids) { ['g33_rest_hook_documentation_attestation'] }

    it 'imports every required SMART Backend Services test from the PAS client suite' do
      expect(expected_ids).to_not be_empty
      expect(expected_ids - imported_ids).to be_empty
    end

    it 'imports nothing the PAS client suite does not define for this client type' do
      expect(imported_ids - expected_ids - locally_defined_ids).to be_empty
    end

    it 'adds the locally defined tests to the imported groups' do
      expect(locally_defined_ids - imported_ids).to be_empty
    end
  end

  describe 'optional exclusion' do
    it 'excludes every optional runnable, not just direct children of the imported groups' do
      optional = all_runnables.reject { |runnable| runnable == suite }.select(&:optional?)

      expect(optional.map(&:id)).to be_empty
    end
  end

  describe 'PAS url rewriting' do
    let(:pas_base_url) { ONCCertificationG33TestKit::G33PASImport.pas_base_url }
    let(:base_url) { ONCCertificationG33TestKit::G33PASImport.base_url }

    it 'resolves run time urls against this suite rather than the PAS client suite' do
      base_urls = imported_pas_tests.map { |test| test.new.base_url }.uniq

      expect(imported_pas_tests).to_not be_empty
      expect(base_urls).to eq([base_url])
    end

    it 'rewrites PAS urls baked into descriptions and input instructions' do
      stale = all_runnables.select do |runnable|
        [runnable.description, runnable.input_instructions].any? { |text| text.to_s.include?(pas_base_url) }
      end

      expect(stale.map(&:id)).to be_empty
    end

    it 'rewrites PAS urls baked into input descriptions' do
      stale = all_runnables.select do |runnable|
        runnable.config.inputs.each_value.any? { |input| input.description.to_s.include?(pas_base_url) }
      end

      expect(stale.map(&:id)).to be_empty
    end
  end

  # The (g)(33) and (j)(21) requirements are added to tests that are imported from the PAS client
  # suite, so they are applied after the fact rather than declared in a test definition.
  describe 'certification requirements' do
    let(:requirements_repo) { Inferno::Repositories::Requirements.new }
    let(:suite_requirement_ids) { requirements_repo.requirements_for_suite(suite.id).map(&:id) }
    let(:mapped_requirement_ids) { ONCCertificationG33TestKit::G33Requirements::REQUIREMENT_MAP.keys }
    let(:certification_requirement_ids) do
      suite_requirement_ids.select { |id| id.start_with?('170.315') }
    end

    it 'declares both certification criteria as requirement sets' do
      sets = suite.requirement_sets.to_h { |set| [set.identifier, set.actor] }

      expect(sets[ONCCertificationG33TestKit::G33Requirements::G33_SET]).to eq('Provider')
      expect(sets[ONCCertificationG33TestKit::G33Requirements::J21_SET]).to eq('Client')
    end

    # A requirement that is renumbered or dropped upstream would otherwise silently stop being
    # verified by anything.
    it 'maps only requirements the suite actually loads' do
      expect(mapped_requirement_ids).to_not be_empty
      expect(mapped_requirement_ids - suite_requirement_ids).to be_empty
    end

    it 'verifies every mapped requirement with at least one runnable' do
      verified = suite.all_verified_requirements

      expect(mapped_requirement_ids - verified).to be_empty
    end

    # The Subscription update and delete API tests are pending, so the requirements that only they
    # would verify are the one remaining gap. Everything else is expected to be covered.
    it 'leaves only the known gaps unverified' do
      verified = suite.all_verified_requirements
      unverified = certification_requirement_ids - verified

      expect(unverified).to contain_exactly(
        "#{ONCCertificationG33TestKit::G33Requirements::J21_SET}@6",
        "#{ONCCertificationG33TestKit::G33Requirements::J21_SET}@7"
      )
    end

    # (g)(33)(ii) has no corresponding test in the PAS client or Subscriptions test kits, so this
    # suite defines the attestation that covers it rather than mapping it onto an imported runnable.
    it 'covers the REST-Hook documentation requirement with an attestation defined here' do
      requirement_id = "#{ONCCertificationG33TestKit::G33Requirements::G33_SET}@9"
      test = all_runnables.find { |runnable| runnable.id.to_s.end_with?('g33_rest_hook_documentation_attestation') }

      expect(test.verifies_requirements).to include(requirement_id)
      expect(ONCCertificationG33TestKit::G33Requirements::REQUIREMENT_MAP).to_not have_key(requirement_id)
    end

    # The certification requirements are added to the IG requirements each test already declares.
    it 'keeps the IG requirements the imported tests declare' do
      test = all_runnables.find do |runnable|
        runnable.id.to_s.end_with?('pas_client_v221_subscription_create_test')
      end

      expect(test.verifies_requirements).to include('hl7.fhir.us.davinci-pas_2.2.1@spec-8')
      expect(test.verifies_requirements).to include(
        "#{ONCCertificationG33TestKit::G33Requirements::J21_SET}@5"
      )
    end
  end

  # The PAS claim endpoint derives both of these from its suite id, which does not carry the version
  # or the prefix here, so both are overridden.
  describe 'claim endpoint' do
    let(:endpoint) { ONCCertificationG33TestKit::G33ClaimEndpoint.allocate }
    let(:suite_paths) do
      Inferno.routes.select { |route| route[:suite]&.id == suite.id }.map { |route| route[:path] }
    end

    it 'reports v2.2.1 rather than falling back to the earlier IG version' do
      expect(endpoint.ig_version).to eq('v2.2.1')
    end

    it 'builds urls under the prefix the endpoints are actually registered at' do
      expect(endpoint.base_url).to eq(ONCCertificationG33TestKit::G33PASImport.base_url)

      subscription_path = endpoint.fhir_subscription_url.split("/custom/#{suite.id}").last

      expect(subscription_path).to start_with(ONCCertificationG33TestKit::G33Options::PAS_V221_PREFIX)
      expect(suite_paths).to include("#{subscription_path}/:id")
    end
  end
end
