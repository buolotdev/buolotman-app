# BoulotMan Mobile — Real User Workflow Test Guide

This guide is for testing the app as a real user across the Client, Technician, and Company roles. It is not a developer-only QA checklist. Complete the workflows in the order below and use separate accounts so that actions made by one role can be verified from the other role.

## 1. Test setup

Use:

- One Android device and one iPhone if available.
- The latest APK or iOS build from this repository.
- A real deployed backend, not a local development URL.
- Three separate accounts:
  - Client account: `client-test-<date>@example.com`
  - Technician account: `technician-test-<date>@example.com`
  - Company account: `company-test-<date>@example.com`
- A second technician account for proposal comparison.
- One test image, one PDF, and one unsupported file such as `.exe`.
- A phone number that can receive CamPay prompts if payment testing is enabled.

Do not reuse an account from another test run. Record each account email, role, verification state, and device used. OTP/email signup is intentionally excluded until the Scala SMTP API is available. Use the currently available authentication method.

## 2. First launch and account safety

For each account:

1. Install the current build.
2. Launch the app while connected to the deployed backend.
3. Register or sign in with the intended role.
4. Close and reopen the app.
5. Confirm the app returns to the same role dashboard.
6. Sign out.
7. Confirm the login screen appears.
8. Sign in again and confirm no other role’s dashboard is shown.
9. Delete the account only in a separate disposable test account, after confirming the explicit confirmation dialog appears.

A deleted account must not reopen the dashboard from an old token.

## 3. Client journey

### Client profile

1. Open Profile.
2. Add or replace the profile picture from the gallery.
3. Add or replace the cover image.
4. Enter the personal details using the appropriate keyboard for each field:
   - Email uses an email keyboard.
   - Phone uses the phone keyboard and country format.
   - Numeric fields reject letters.
   - Dropdowns do not behave as free-text fields.
5. Save.
6. Leave the screen and return.
7. Force-close and reopen the app.
8. Confirm every value and both images remain saved.
9. Open the public profile from another role and confirm the cover and profile images are visible.

### Create a task

1. Open Post a task.
2. Enter a realistic title and detailed description.
3. Select a category from the backend list.
4. Add multiple required skills.
5. Enter minimum and maximum numeric budgets.
6. Select urgency and service type.
7. Enter city, schedule, and deadline using the relevant controls.
8. Open the map picker.
9. Search for a supported-country location.
10. Drag the map pin to a precise position.
11. Confirm the selected address, latitude, and longitude appear outside the map page.
12. Add an image and a PDF attachment.
13. Reject or remove an unsupported file type.
14. Select contact preferences.
15. Save the task.
16. Reopen it from My Tasks.
17. Force-close and reopen the app.
18. Confirm title, description, category, skills, budgets, location, coordinates, schedule, deadline, urgency, service type, materials, contact methods, and attachments are still present.

### Receive and manage proposals

1. On the technician account, browse the client’s task.
2. Submit one fixed-price proposal.
3. Submit a second proposal from another technician.
4. Return to the client account.
5. Open the task and confirm both proposals are visible with amount, duration, message, technician identity, and status.
6. Reject one proposal.
7. Confirm its status changes and its action buttons become disabled.
8. Accept the other proposal.
9. Confirm the task becomes assigned to that technician.
10. Confirm the rejected/pending proposal cannot be accepted after assignment.
11. Open Message technician and send a text message and image attachment.
12. Confirm the technician receives the message without refreshing the entire app.

### Client project and escrow journey

1. Open the assigned project.
2. Confirm client, technician, task, budget, status, milestones, progress, deliverables, and escrow state are visible.
3. Fund escrow with the wallet option using a controlled test balance, or use CamPay only with an approved test amount.
4. Confirm the payment status changes only after the backend confirms it.
5. Confirm a failed or cancelled payment does not mark escrow funded.
6. Wait for the technician to submit a deliverable.
7. Review the deliverable and evidence.
8. Approve the completion or release the relevant escrow payment.
9. Confirm the transaction and project status update after reopening the project.
10. Open a dispute from the project and confirm the dispute record is created.

## 4. Technician journey

### Technician profile and verification

1. Complete the profile fields with realistic information.
2. Add a profile picture and cover image from the gallery.
3. Add portfolio items with title, description, category, and image.
4. Add services, pricing, skills, availability, tools, and payout preferences.
5. Open verification.
6. Upload the required front ID, back ID, certificate/license, and selfie/photo using the appropriate file picker.
7. Confirm previews appear before submission.
8. Try an unsupported file type and an oversized file.
9. Confirm both are rejected with a clear error.
10. Submit the verification package.
11. Confirm each document has its own pending state.
12. From an admin account, approve or reject a document.
13. Return to the technician account and confirm the exact admin result and feedback appear after reload.

### Unverified restrictions

Before approval, verify that the technician can view the dashboard, profile, wallet, messages, and notifications, but cannot:

- Browse tasks.
- Submit bids.
- Publish restricted services.
- Accept work requiring verification.

Each blocked action must show a verification explanation rather than failing silently.

### Technician bid and project journey

1. After verification, browse tasks.
2. Search by title/city.
3. Filter by category, skills, urgency, service type, budget range, and location.
4. Open task details and confirm coordinates, attachments, client details, bid count, views, escrow state, milestones, questions, and contact methods.
5. Submit a fixed-price bid with amount, duration, message, and extra notes.
6. Confirm the service-fee and payout preview.
7. Try submitting a second active bid for the same task and confirm duplicate prevention.
8. Open My Bids and confirm pending, accepted, rejected, and withdrawn states.
9. Withdraw a pending bid and confirm it cannot be withdrawn again.
10. After acceptance, open the project workspace.
11. Send a message to the client.
12. Submit a deliverable with notes and evidence.
13. Confirm the client can see it.
14. Confirm completion and escrow state update only through valid assigned-technician actions.

### Technician wallet

1. Confirm available balance, pending escrow, earnings, withdrawn amount, and transactions.
2. Attempt a withdrawal larger than the available balance.
3. Confirm the request is rejected without changing the balance.
4. Submit a valid payout request with a valid phone/account.
5. Confirm the transaction and balance update after reopening the wallet.

## 5. Company journey

### Company profile and verification

1. Complete company name, registration number, size, founded year, industry, services, expertise, country, city, headquarters, coordinates, business hours, website, description, team size, and response time.
2. Add company logo and cover image.
3. Save, leave, force-close, reopen, and confirm all values persist.
4. Upload the company compliance documents using the company document flow.
5. Confirm company documents are not displayed as technician documents.
6. Test preview, full-screen preview, replacement, invalid file type, and oversized file behavior.
7. Approve/reject from admin and verify the company sees the correct state and feedback.

### Company services

1. Create a service with title, category, pricing model, description, status, and image.
2. Confirm the image is uploaded and displayed.
3. Preview the service.
4. Activate and deactivate it.
5. Edit it only if the backend accepts the update.
6. Delete it with confirmation.
7. Confirm an unverified company cannot publish restricted services.

### Company projects and quotes

1. Create a project while verified.
2. Confirm title, client name, budget, timeline, location, status, progress, payment status, and milestone counts persist.
3. Open project details.
4. Update progress and status.
5. Reload and confirm the backend value remains.
6. Open a quote request.
7. Review client identity, requested service, budget, deadline, location, priority, summary, technical details, and attachments.
8. Approve one quote and reject another.
9. Confirm approved/rejected actions become disabled.
10. Convert an approved quote to a project if the backend returns the project conversion successfully.
11. Message the client from the quote when a client identity is supplied by the backend.

### Company wallet

1. Open Wallet from Settings and from the dashboard.
2. Confirm both routes open the same real wallet screen.
3. Check wallet balance and transaction history.
4. Check CamPay balance.
5. Top up with a controlled test payment and wait for status polling.
6. Confirm failed, pending, and successful states are distinct.
7. Withdraw a valid amount to a valid payout phone.
8. Try an invalid amount and insufficient balance.
9. Confirm the company wallet does not expose technician-only subscription controls.

### Technician plans and subscriptions

1. Open Wallet from the technician navigation.
2. Open Plans and subscriptions.
3. Select monthly and yearly billing.
4. Confirm Pro and Enterprise prices match the website.
5. Upgrade only with a disposable technician test account.
6. Verify the backend response, wallet transaction, notification, and updated technician account state.

## 6. Messaging and presence

Use two devices or two logged-in accounts.

1. Start a conversation from an accepted proposal, project, quote, and public profile where supported.
2. Send messages from both sides.
3. Confirm new messages appear without manual refresh while both chats are open.
4. Send an image, PDF, and other supported file.
5. Confirm preview, download/open behavior, and sender alignment.
6. Mark a conversation read and confirm unread counts update.
7. Close one app, wait, and reopen it.
8. Confirm missed messages are loaded from the backend.
9. Disconnect one device from the network and reconnect it.
10. Confirm WebSocket reconnects or the REST history restores the conversation.
11. Confirm online/offline presence and last-seen behavior update realistically.

## 7. Notifications

On Android and iOS:

1. Allow notification permission.
2. Sign in and confirm the device token is registered.
3. Close the app completely.
4. Trigger a message, bid, verification, project, deliverable, and payment event from another role.
5. Confirm each notification appears while the app is closed.
6. Confirm the BoulotMan app icon appears.
7. Tap the notification and confirm it opens the correct task, project, message, or verification screen.
8. Open the notification list and mark one notification read.
9. Mark all notifications read.
10. Disable permission and confirm the app remains usable with a clear notification state.

## 8. Data persistence and permission checks

For every form and action:

1. Save or submit it.
2. Leave the screen.
3. Force-close the app.
4. Reopen and reload from the backend.
5. Confirm the value is not merely stored locally.
6. Try the same action from the wrong role.
7. Try the same action while unverified.
8. Confirm unauthorized actions are disabled or rejected with a useful message.

Pay special attention to numeric budgets, percentages, dates, country/phone formats, coordinates, file fields, status values, and IDs. A success message is valid only when a reload confirms the backend saved the data.

## 9. Failure and recovery tests

Test with the network disconnected or a temporarily unavailable backend:

- Login failure.
- Task save failure.
- Bid submission failure.
- Attachment upload failure.
- Payment timeout.
- WebSocket disconnect.
- Notification permission denied.
- Invalid or expired session.
- Deleted account with an old token.

The app must show a readable error, stop the loading state, preserve already-entered data where practical, and never show a false success state.

## 10. Final acceptance criteria

The build is ready for real user testing only when:

- Client, technician, and company accounts can complete their major workflows.
- Actions made by one role are visible to the intended other role.
- Verification restrictions work before and after admin approval.
- Payment states match backend responses.
- Wallet balances and transactions reload correctly.
- Messages arrive live and history survives reconnects.
- Closed-app notifications arrive on Android and iOS with the app icon.
- Images, documents, coordinates, numeric fields, and status values persist.
- No screen reports success for a local-only change.
- OTP/email signup is excluded from acceptance until the Scala SMTP API is connected.
