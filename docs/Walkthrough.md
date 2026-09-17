This walkthrough introduces the **Inferno ONC Certification (g)(33)
Prior Authorization Support API Test Kit** by
demonstrating its use as an automated testing tool for the
[§ 170.315(g)(33) prior authorization submission criterion](https://healthit.gov/test-method/provider-prior-authorization-api-prior-authorization-support)
of the ONC Health IT Certification Program. At the end of this walkthrough,
you will be able to use the test kit to evaluate a Health IT Module for
conformance to the (g)(33) certification criterion.

This test kit evaluates a **Health IT Module**, specifically a provider system
that submits prior authorization requests to a payer. Each step of this
walkthrough describes the kinds of actions that a tester would take within their
Health IT Module when running these tests against it.

During the tests, Inferno will act as a PAS payer server for the Health IT
Module to interact with. Inferno publishes simulated `$submit`, `$inquire`, and
Subscription endpoints, waits for the Health IT Module to invoke them, and then
validates the requests it received and the way the Health IT Module handled
Inferno's responses. Because Inferno is waiting to be called, most scenarios
pause on a 'User Action Required' dialog. Inferno will only associate requests
with your session while one of these dialogs is active. Once it is active the
tester takes actions within the Health IT Module that trigger the relevant
requests and acknowledges within the Inferno UI once all requests have been sent
so that Inferno knows to start evaluating them.

NOTE: If multiple people are running this demonstration at the same time, unexpected results
may occur. If you see strange behavior, pause execution and try again later.

The following steps necessary to complete certification testing are described in more detail below:
*   [Step 1: Create a new (g)(33) Test Session](#step-1-create-a-new-g33-test-session)
*   [Step 2: Configure the Health IT Module Under Test](#step-2-configure-the-health-it-module-under-test)
*   [Step 3: Perform Client Registration Tests](#step-3-perform-client-registration-tests)
*   [Step 4: Perform Subscription Setup Tests](#step-4-perform-subscription-setup-tests)
*   [Step 5: Perform PAS Workflow Tests](#step-5-perform-pas-workflow-tests)
*   [Step 6: Perform Must Support Element Tests](#step-6-perform-must-support-element-tests)
*   [Step 7: Perform Error Handling Tests](#step-7-perform-error-handling-tests)
*   [Step 8: Review Authentication Interactions](#step-8-review-authentication-interactions)
*   [Step 9: Complete Visual Inspection and Attestation](#step-9-complete-visual-inspection-and-attestation)
*   [Step 10: Review Results](#step-10-review-results)

## Step 1: Create a new (g)(33) test session

* Go to <https://inferno.healthit.gov>.
* Click the 'ONC (g)(33) Prior Authorization Support API Test Kit' button under 'ONC Health
  Certification Program', which is an Inferno test kit developed specifically to
  test the requirements of the (g)(33) criterion in the ONC Health IT
  Certification Program.
* Click 'Create Test Session' to start testing.

This creates a new test session. The header states which version of the test kit
is being used and which client version was selected.

The tests are organized into seven groups that in sum cover the requirements of the criterion:

1.  **Client Registration** - the Health IT Module registers with Inferno as a SMART
    confidential asymmetric client and is given Inferno's simulated PAS endpoints.
2.  **Subscription Setup** - the Health IT Module creates a Subscription so that it can be
    notified when pended prior authorization requests are updated.
3.  **PAS Workflows** - the Health IT Module participates in complete prior authorization
    interactions, covering approved, denied, pended, updated, and payer-modified requests.
4.  **Must Support Elements** - the Health IT Module demonstrates that it can send and receive
    all PAS-defined profiles and their must support elements.
5.  **Error Handling** - the Health IT Module handles both HTTP-level operation failures and
    business-level processing errors returned within a response bundle.
6.  **Review Authentication Interactions** - Inferno verifies that the token requests made during
    the earlier groups conformed to SMART Backend Services requirements.
7.  **Visual Inspection and Attestation** - the tester confirms the Health IT Module conforms to
    requirements that are currently not verified through automated testing.

The groups are intended to be run in order. Later groups depend on data collected
during earlier ones. In particular, 'Client Registration' records the client id
that ties incoming requests to your session, 'Subscription Setup' creates the
Subscription that the pended workflow notifies against, and 'Review
Authentication Interactions' evaluates the token requests made while running the
earlier groups.

## Step 2: Configure the Health IT Module under test

Inferno simulates a PAS payer server. In order to pass the certification tests,
Health IT Modules will need to be configured to submit prior authorization
requests to Inferno's endpoints and to authenticate using SMART Backend
Services.

Inferno's simulated PAS endpoints:
*   FHIR base URL: `https://inferno.healthit.gov/suites/custom/g33_certification/pas_v221/fhir`
*   Prior authorization submission: `<FHIR base>/Claim/$submit`
*   Prior authorization inquiry: `<FHIR base>/Claim/$inquire`
*   Subscription creation: `<FHIR base>/Subscription`
*   SMART discovery: `<FHIR base>/.well-known/smart-configuration`

The exact URLs for your session are displayed during the 'Client Registration'
group, and are the authoritative values to configure.

## Step 3: Perform Client Registration tests

The 'Client Registration' group records the connection details that the rest of
the tests rely on, so it must be run first. Inferno will not accept prior authorization 
requests while waiting during this group. However, the client system will be able
to make token requests to validate connectivity and client registration.

*   Select '1 Client Registration' and click 'RUN TESTS'.
*   Provide the registration inputs:
    *   **Client Id**: the client id Inferno will expect the Health IT Module to use
        when requesting access tokens. Testers may provide a specific value; if
        none is provided, the Inferno session id is used. This value identifies
        which test session an incoming request belongs to, so the Health IT
        Module must be configured with exactly this value.
    *   **SMART Confidential Asymmetric JSON Web Key Set (JWKS)**: the Health IT
        Module's JWK Set, either as a publicly accessible URL or as raw JSON.
        Inferno uses this to verify the signature on the client assertions the
        Health IT Module sends when requesting tokens.
*   Click 'SUBMIT'.
*   Inferno displays its simulated server details, including the FHIR base URL
    and token endpoint. Configure the Health IT Module to connect to Inferno at
    these endpoints, test token requests if desired, then click the confirmation link in the dialog.

## Step 4: Perform Subscription Setup tests

The (g)(33) criterion requires support for subscriptions so that the Health IT
Module can be notified when a pended prior authorization is updated. This group
verifies that the Health IT Module can create a conformant Subscription and
respond to Inferno's handshake.

*   Select '2 Subscription Setup' and click 'RUN TESTS'.
*   Optionally provide the **Client Notification Access Token**: the bearer token
    that Inferno will send on requests to the Health IT Module's rest-hook
    notification endpoint, including the handshake notification sent after
    Subscription creation. This is not needed if the Health IT Module will create
    a Subscription with an appropriate header value in the `channel.header`
    element. If a value for the `authorization` header is provided in
    `channel.header`, this input will override it.
*   When the 'User Action Required' dialog appears, submit a `POST` containing a
    PAS-conformant Subscription resource to the URL shown in the dialog. The test
    descriptions describe the requirements checked, and any that the Subscription
    does not meet are reported in the results.
*   Upon receipt, Inferno will send a handshake notification to the endpoint named in
    the Subscription to verify that notifications can be sent to it.

## Step 5: Perform PAS Workflow tests

The workflow tests verify that the Health IT Module can participate in complete
end-to-end prior authorization interactions, initiating requests and reacting
appropriately to the responses returned. This group contains five sub-groups:

*   **Approval Workflow** - a request that the payer approves.
*   **Denial Workflow** - a request that the payer denies.
*   **Pended Workflow** - a request the payer pends, with the final decision
    delivered later through a subscription notification.
*   **Claim Updates** - a sequence of four submissions: an initial request, an
    update adding an item, an update modifying and canceling items, and an update
    canceling the entire request.
*   **Payer Modifications** - a request the payer partially authorizes with
    modified items.

Each sub-group follows the same pattern:

*   Select the sub-group and click 'RUN TESTS'.
*   Optionally provide the responses Inferno should return. Which inputs appear
    depends on the sub-group being run, so running 'RUN ALL TESTS' at the level of
    'PAS Workflows' presents all of them at once:
    *   **Approval Workflow**: Claim approved response JSON
    *   **Denial Workflow**: Claim denied response JSON
    *   **Pended Workflow**: Claim pended response JSON, Claim updated
        notification JSON, and Inquire approved response JSON
    *   **Claim Updates**: Initial claim response JSON, Add-item update response
        JSON, Modify-and-cancel update response JSON, and
        Cancel-entire-request update response JSON
    *   **Payer Modifications**: Claim modified response JSON
*   When the 'User Action Required' dialog appears, submit a prior authorization
    request from the Health IT Module to the URL shown.
*   Inferno validates the request bundle and the response bundle it returned, and
    then asks you to attest that the Health IT Module displayed the decision
    appropriately.

These response inputs are all optional. When one is populated, Inferno modifies
the provided message before returning it, for example to apply current
timestamps; see [Inferno modifications of tester-provided responses and
notifications](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Details#inferno-modifications-of-tester-provided-responses-and-notifications)
in the PAS Test Kit wiki for the details. When one is left blank, Inferno instead
generates a response from the request it received; see [Generation
logic](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Details#generation-logic)
in the PAS Test Kit wiki for how those responses are built.

## Step 6: Perform Must Support element tests

During these tests, the Health IT Module shows that it supports all PAS-defined
profiles and the must support elements defined in them, both in the requests it
sends and in the responses it can receive.

*   Select '4 Must Support Elements' and click 'RUN TESTS'.
*   Optionally provide sets of `$submit` and `$inquire` response bundles for
    Inferno to return. Because Inferno's generated responses do not include every
    must support element, providing responses that do is how a Health IT Module
    demonstrates it can receive them.
*   When the 'User Action Required' dialog appears, submit additional `$submit`
    and `$inquire` requests demonstrating coverage of any must support elements
    not already exercised during the workflow tests.

Inferno considers requests made during the PAS Workflows group as well, so only
profiles and elements not already demonstrated there need to be submitted here.

Not every Health IT Module collects every must support element, and the PAS
implementation guide does not require that they do. Three of the tests in this
group therefore offer an attestation when coverage is incomplete:

*   'At least one instance of a request profile (PAS Medication Request, PAS
    Service Request, PAS Device Request, or PAS Nutrition Order)...'
*   'All must support elements for other profiles referenced by Claim
    submissions are observed on $submit requests'
*   'All must support elements for other profiles referenced by Claim inquiries
    are observed on $inquire requests'

If every must support element was observed, these tests pass without asking for
anything further. If any were not, the test pauses and lists the unobserved
elements, and the tester attests whether the Health IT Module collects that data:

*   Follow the link indicating the statement is **true** if the Health IT Module
    does **not** collect the data for the listed elements. The test passes.
*   Follow the link indicating the statement is **false** if it does collect
    them, meaning they should have appeared in the requests. The test fails.

The unobserved elements are also recorded as `info` messages on the test result,
so they can be reviewed after the run.

## Step 7: Perform Error Handling tests

The error handling tests verify that the Health IT Module can appropriately
handle prior authorization error responses from the payer. This group contains
two sub-groups:

*   **Operation Failure** - Inferno returns an HTTP error status with an
    `OperationOutcome` rather than a response bundle.
*   **Processing Errors** - Inferno returns a response bundle containing
    business-level error entries.

For each, submit a request when prompted, and then attest that the Health IT
Module handled the error appropriately.

## Step 8: Review Authentication Interactions

This group does not require any new interaction with the Health IT Module.
Inferno verifies that the access token requests made during the earlier groups
conformed to the SMART Backend Services requirements, and that the issued tokens
were used on the prior authorization requests.

*   Select '6 Review Authentication Interactions' and click 'RUN TESTS'.

Because these tests evaluate requests made earlier, at least one of the
preceding groups that exchanges prior authorization requests must have been run
first. If no token requests were made, the tests will skip rather than fail.

## Step 9: Complete Visual Inspection and Attestation

Not every requirement can be verified automatically. This group collects
attestations for the remaining requirements of the criterion.

*   Select '7 Visual Inspection and Attestation'.
*   Each test asks you to confirm that the Health IT Module meets one or more **SHALL** requirements
    by selecting 'Yes' or 'No' in the input with the same name as the test before starting the run.
    You are responsible for confirming that the Health IT Module meets all requirements
    associated with a test before selecting "Yes" on the attestation input with the same name as
    the test. Selecting 'No' fails the test.
*   You may use the accompanying notes field to record supporting details.
    Notes are recorded in the test result.
*   To review the exact requirement text behind a test, open its 'ABOUT' tab and follow the
    'View Specification Requirements' link.

One of these tests, 'Subscriptions client endpoint capabilities for the "REST-Hook" channel
include complete accompanying technical documentation', covers the documentation requirement in
§ 170.315(g)(33)(ii). Have the technical documentation for the Health IT Module's REST-Hook
notification endpoint on hand before the run, since the attestation covers whether that
documentation is complete.

These tests cover areas that for now are very broad or otherwise difficult to demonstrate or mechanically verify.

## Step 10: Review Results

All tests have now been completed. To print out a copy of the results, click the 'Report' icon in
the menu on the left and then the 'Print' icon within that view. Export this report if you would
like to share the results.
