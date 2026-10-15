This walkthrough introduces the **Inferno ONC Certification (g)(33)
Prior Authorization Support API Test Kit** by
demonstrating its use as an automated testing tool for the
[§ 170.315(g)(33) prior authorization submission criterion](https://healthit.gov/test-method/provider-prior-authorization-api-prior-authorization-support)
of the ONC Health IT Certification Program. At the end of this walkthrough,
you will be able to use the test kit to evaluate a Health IT Module for
conformance to the (g)(33) certification criterion.

This test kit evaluates a **Health IT Module**, specifically a provider system
that submits prior authorization requests to a payer. Each step of this walkthrough
describes the kinds of actions that a tester would take within their Health IT Module
when running these tests against it. Many of the steps also include demonstration
execution details for using the [ONC-hosted instance](https://inferno.healthit.gov/suites/g33_certification)
to evaluate the behavior of the publicly available [Da Vinci burden reduction BR Provider reference implementation](https://br-provider.davinci.hl7.org/).
Note that the reference implementation may not pass all tests.

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

The following steps necessary to complete certification testing are described in more detail below:
*   [Step 1: Create a new (g)(33) Test Session](#step-1-create-a-new-g33-test-session)
*   [Step 2: Perform Client Registration Tests and Configure the Health IT Module Under Test](#step-2-perform-client-registration-tests-and-configure-the-health-it-module-under-test)
*   [Step 3: Perform Subscription Setup Tests](#step-3-perform-subscription-setup-tests)
*   [Step 4: Perform PAS Scenario Tests](#step-4-perform-pas-scenario-tests)
*   [Step 5: Perform Must Support Element Tests](#step-5-perform-must-support-element-tests)
*   [Step 6: Subscription Update and Deletion](#step-6-subscription-update-and-deletion)
*   [Step 7: Review Authentication Interactions](#step-7-review-authentication-interactions)
*   [Step 8: Complete Visual Inspection and Attestation](#step-8-complete-visual-inspection-and-attestation)
*   [Step 9: Review Results](#step-9-review-results)

## Step 1: Create a new (g)(33) test session

* Go to <https://inferno.healthit.gov>.
* Click the 'ONC (g)(33) Prior Authorization Support API Test Kit' button under 'ONC Health IT
  Certification Program', which is an Inferno test kit developed specifically to
  test the requirements of the (g)(33) criterion in the ONC Health IT
  Certification Program.
* Click 'Create Test Session' to start testing.

This creates a new test session. The tests are organized into seven groups that in
sum cover the requirements of the criterion:

1.  **Client Registration** - the Health IT Module registers with Inferno as a SMART
    confidential asymmetric client and is given Inferno's simulated PAS endpoints.
2.  **Subscription Setup** - the Health IT Module creates a Subscription so that it can be
    notified when pended prior authorization requests are updated.
3.  **PAS Scenarios** - the Health IT Module participates in complete prior authorization
    interactions, covering approved, denied, pended, updated, and payer-modified requests.
4.  **Must Support Elements** - the Health IT Module demonstrates that it can send and receive
    all PAS-defined profiles and their must support elements.
5.  **Subscription Update and Deletion** - the Health IT Module can update and delete Subscriptions.
6.  **Review Authentication Interactions** - Inferno verifies that the token requests made during
    the earlier groups conformed to SMART Backend Services requirements.
7.  **Visual Inspection and Attestation** - the tester confirms the Health IT Module conforms to
    requirements that are currently not verified through automated testing.

The groups are intended to be run in order. Later groups depend on data collected
during earlier ones. In particular, 'Client Registration' records the client id
that ties incoming requests to your session, 'Subscription Setup' creates the
Subscription that the pended scenario notifies against, and 'Review
Authentication Interactions' evaluates the token requests made while running the
earlier groups. Tests using notifications, including the 'Pended Response' scenario
and potentially the 'Must Support Elements' tests cannot be run after the 
'Subscription Update and Deletion' tests.

## Step 2: Perform Client Registration tests and configure the Health IT Module under test

The 'Client Registration' group verifies and records the connection details that
the rest of the tests rely on, so it must be run first. Inferno will not accept
prior authorization requests while waiting during this group. However, the client
system will be able to make token requests to validate connectivity and client registration.

*   Select '1 Client Registration' and click 'RUN TESTS'.
*   Provide the registration inputs:
    *   **Client Id**: the client id Inferno will expect the Health IT Module to use
        when requesting access tokens. Testers may provide a specific value; if
        none is provided, the Inferno session id is used. This value identifies
        which test session an incoming request belongs to, so it should be unique
        and the Health IT Module must be configured with exactly this value.
    *   **SMART Confidential Asymmetric JSON Web Key Set (JWKS)**: the Health IT
        Module's JWK Set, either as a publicly accessible URL or as raw JSON.
        Inferno uses this to verify the signature on the client assertions the
        Health IT Module sends when requesting tokens.
*   Click 'SUBMIT'.
*   Inferno displays its simulated PAS server details, including the FHIR base URL
    and token endpoint. Configure the Health IT Module to connect to Inferno at
    these endpoints, test token requests if desired, then click the confirmation
    link in the dialog.

### Reference implementation registration example

The input values to register the BR Provider reference implementation can be pulled
in by applying the "Da Vinci BR Provider Reference Implementation" preset before
running the "Registration" group. The specific values are:
- **Client Id**: left blank so that the session id is chosen for the client id (this ensures that no other session running this demonstration will conflict with it)
- **SMART Confidential Asymmetric JSON Web Key Set (JWKS)**: `https://br-provider.davinci.hl7.org/api/security/jwks`

To configure the BR Provider reference implementation to connect to your session
1. In Inferno, apply preset "Da Vinci BR Provider reference implementation" using
   the dropdown in the upper right. Then run group "1 Client Registration" without
   changing any of the inputs. When the dialog appears indicating Inferno is ready
   to receive requests, continue to the next step.
1. In a separate tab, navigate to https://br-provider.davinci.hl7.org/ and login
   (no password needed) as a practitioner (any).
1. Configure the connection to Inferno's simulated PAS server by:
   1. Clicking the gear icon in the upper right to open the settings dialog.
   1. Select the "Payer" tab
   1. Use the "Server" dropdown to select the "Custom" option.
   1. In the "CDS Services URL" input, put `https://br-payer.davinci.hl7.org/cds-services`.
   1. In the "FHIR" input, put Inferno's FHIR url displayed in the "User Action Required"
      dialog on the Inferno tab (e.g., `https://inferno.healthit.gov/suites/custom/g33_certification/pas_v221/fhir`).
   1. From the "Authentication" dropdown, select `SMART Backend Services`
   1. In the "Client ID" input, copy the client id displayed in the "User Action Required"
     dialog on the Inferno tab (11 character alpha-numeric value).
   1. Click the "Bypass payor-handled check" box.
   1. Click the "Save" button and close the dialog to complete the setup.
1. Back in Inferno, click the link to confirm the configuration and continue the tests.

## Step 3: Perform Subscription Setup tests

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

### Reference implementation subscriptions example

This demonstration does not currently show how to trigger Subscriptions for a
pended workflow demonstration with the BR Provider reference implementation.

## Step 4: Perform PAS Scenario tests

The scenario tests verify that the Health IT Module can participate in complete
end-to-end prior authorization interactions, initiating requests and reacting
appropriately to the responses returned. This group contains seven sub-groups:

*   **Approval Workflow** - a request that the payer approves.
*   **Denial Workflow** - a request that the payer denies.
*   **Pended Workflow** - a request the payer pends, with the final decision
    delivered later through a subscription notification.
*   **Claim Updates** - a sequence of four submissions: an initial request, an
    update adding an item, an update modifying and canceling items, and an update
    canceling the entire request.
*   **Payer Modifications** - a request the payer partially authorizes with
    modified items.
*   **Operation Failure** - a request that the payer fails to process.
*   **Processing Errors** - a request for which the payer returns business errors.

Each sub-group follows the same pattern:

*   Select the sub-group and click 'RUN TESTS'.
*   Optionally provide the responses Inferno should return. Which inputs appear
    depends on the sub-group being run, so running 'RUN ALL TESTS' at the level of
    'PAS Workflows' presents all of them at once:
    *   **Approval Workflow**: Claim approved response JSON
    *   **Denial Workflow**: Claim denied response JSON
    *   **Pended Workflow**: Claim pended response JSON, Claim updated
        notification JSON, and Client Notification Access Token
    *   **Claim Updates**: Initial claim response JSON, Add-item update response
        JSON, Modify-and-cancel update response JSON, and
        Cancel-entire-request update response JSON
    *   **Payer Modifications**: Claim modified response JSON
    *   **Operation Failure**: Operation Failure OperationOutcome JSON (Required),
        Operation Failure HTTP Status Code
    *   **Processing Errors** - Processing Error Response Bundle JSON (Required)
*   When the 'User Action Required' dialog appears, submit a prior authorization
    request from the Health IT Module to the URL shown.
*   Inferno validates the request bundle and the response bundle it returned, and
    then asks you to attest that the Health IT Module displayed the decision
    appropriately.

Most response inputs are optional. When one is populated, Inferno modifies
the provided message before returning it, for example to apply current
timestamps; see [Inferno modifications of tester-provided responses and
notifications](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Details#inferno-modifications-of-tester-provided-responses-and-notifications)
in the PAS Test Kit wiki for the details. When an optional one is left blank,
Inferno instead generates a response from the request it received;
see [Generation
logic](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Details#generation-logic)
in the PAS Test Kit wiki for how those responses are built.

### Reference implementation approval scenario example

Within the BR Provider system, you can trigger a prior-authorization request to
Inferno in the following way:
1. In Inferno, run group "3.1 Approval Response" without any changes to the inputs so
   that the default mocked response will be used. When the dialog appears
   indicating Inferno is ready to receive requests, return to the tab with the
   reference implementation.
1. In the reference implementation tab, select patient "Roosevelt, Theodor Alan
   Roosevelt" to open their chart.
1. Start an encounter by clicking the "Start Encounter" button in the far upper
   right of the chart window.
1. Select the "E0424 - Stationary compressed gas O2" order (which will require
   prior authorization for this patient) from the "Add Order" dropdown and click
   the "+ Add" button to the right of the dropdown.  
1. Click the "Sign all Orders" button at the bottom of the chart frame (scroll down).
   On the next screen, click the "Confirm & Sign" button. This will trigger hook
   requests and within a few seconds you should see authorization details for the
   order, including an option to "Submit PA".
1. Click the option to "Submit PA" and then click the "Submit Prior Authorization"
   button on the next screen. The response should come back and be displayed
   as "Approved".
1. Return to the Inferno tab, which will have begun to evaluate the prior authorization
   interaction. A "User Action Required" dialog will appear asking for confirmation
   that the order displayed as having prior authorization "approved". Click the
   appropriate answer based on what you saw in the reference implementation. This
   will complete the tests.

This walkthrough doesn't contain details on running the other scenarios against
the BR Provider reference implementation, but execution would proceed in a similar
way.

## Step 5: Perform Must Support element tests

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

## Step 6: Subscription Update and Deletion

During these tests, the Health IT Module shows that it can update and delete
the Subscription created during the "Subscription Setup" group. Because
that Subscription is used by Inferno to deliver notifications, this group
needs to be run after all PAS requests have been sent to Inferno. If additional
PAS requests that will require notifications need to be sent, re-run the
"Subscription Setup" group to create a new Subscription.

To run
*   Select '5 Subscription Update and Deletion' and click 'RUN TESTS'.
*   When the 'User Action Required' dialog appears, trigger from the
    Health IT Module a FHIR update followed by a delete interaction on the indicated Subscription.
*   Once all requests have been made, click the link in the  'User Action
    Required' dialog to continue the tests. Inferno will evaluate the
    requests for conformance.

### Reference implementation subscriptions example

This demonstration does not currently show how to trigger Subscription updates
within the BR Provider reference implementation.

## Step 7: Review Authentication Interactions

This group does not require any new interaction with the Health IT Module.
Inferno verifies that the access token requests made during the earlier groups
conformed to the SMART Backend Services requirements, and that the issued tokens
were used on the prior authorization requests.

*   Select '6 Review Authentication Interactions' and click 'RUN TESTS'.

Because these tests evaluate requests made earlier, at least one of the
preceding groups that exchanges prior authorization requests must have been run
first. If no token requests were made, the tests will skip rather than fail.

### Reference implementation authentication interactions

After completing the approval workflow demonstration in step 4, this group
can be run and should pass for the reference implementation.

## Step 8: Complete Visual Inspection and Attestation

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

One of these tests, 'Health IT Module documentation includes technical details on its ability to
receive Subscription notifications over a "REST-Hook" endpoint', covers the documentation
requirement in § 170.315(g)(33)(ii). Have the technical documentation for the Health IT Module's
REST-Hook notification endpoint on hand before the run, since the attestation covers whether it
includes those details.

These tests cover areas that for now are very broad or otherwise difficult to demonstrate or mechanically verify.

## Step 9: Review Results

All tests have now been completed. To print out a copy of the results, click the 'Report' icon in
the menu on the left and then the 'Print' icon within that view. Export this report if you would
like to share the results.
