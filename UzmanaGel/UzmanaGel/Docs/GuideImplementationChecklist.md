Guide Implementation Checklist

Last updated: 2026-07-27

This document tracks the implementation status of the iOS service-customer matching platform guide.

Status meanings:

Completed: Implemented and tested or already available in the project.

Partially Completed: Implemented partly, needs improvement, testing, or production hardening.

Missing / To Do: Not implemented yet.

Blocked: Waiting for Apple Developer setup, external payment/backend support, or another dependency.

Current Priority Order

Protect sensitive provider data and verification documents.

Harden messaging and notification delivery with multi-device tests.

Complete payment and reservation checkout.

Add automated tests and release preparation.

1. Project Planning and Architecture

Completed

SwiftUI is used as the main UI framework.

MVVM-style structure is used with View, ViewModel, Model, Repository, and Service layers.

Repository pattern is used for Firebase data access.

Firebase Authentication, Cloud Firestore, Firebase Storage, and Cloud Functions are integrated.

NavigationStack is used in main flows.

GitHub feature branch and pull request workflow is used.

Firestore and Storage rules are stored in the repository.

Firebase CLI deployment configuration exists in firebase.json.

Guide implementation checklist is versioned in the repository.

Partially Completed

Some large Swift files still contain multiple screens and should be split.

Naming, folder structure, and dependency boundaries still need standardization.

Some ViewModels still contain UI/platform responsibilities.

Provider/customer feature screens from different contributors need architecture consistency review.

Missing / To Do

Expand the main README with architecture and setup documentation.

Add module ownership and dependency documentation.

Add a documented Firebase emulator workflow.

Continue safe file-by-file refactoring.

2. Firebase and Backend Setup

Completed

Firebase Auth is connected.

Firestore is connected.

Firebase Storage is connected.

Cloud Functions are deployed in europe-west1.

Firebase project is on Blaze plan.

Phone Auth / OTP works with Firebase test phone numbers.

Firestore rules are versioned and deployed from the repository.

Storage rules are versioned in the repository.

FCM token registration and token refresh saving are implemented.

Callable Functions exist for secure admin review moderation.

Callable Functions exist for secure provider application moderation.

Push notification helper infrastructure exists in Cloud Functions.

Admin custom claims are used for privileged backend operations.

Partially Completed

Real phone number OTP can still be throttled after repeated attempts.

APNs/FCM production configuration needs final Apple Developer review.

Cloud Functions need structured logging and monitoring review.

Notification retries and delivery analytics are not complete.

Missing / To Do

Firebase Analytics event plan.

Crashlytics production setup review.

Remote Config review.

Emulator-based rules and Functions tests.

Production alerting for Cloud Functions failures.

3. Authentication and User Management

Completed

Email/password login and signup exist.

Session handling exists through SessionViewModel.

User role handling exists.

Login attempt tracking exists.

Google login flow exists.

Phone Auth / OTP flow works with Firebase test phone numbers.

Expert signup and OTP flow were tested.

Forgot-password email flow was tested.

Admin routing exists.

Admin access is protected by a Firebase custom claim.

Expert application statuses support:

Draft

Pending

Documents Required

Rejected

Approved

Expert can update requested documents and resubmit an application.

Admin decision notes are shown to the expert.

Approved experts can unlock listing creation when profile completion requirements are met.

Partially Completed

Email verification flow needs final product review.

User onboarding can be simplified and standardized.

Real phone number OTP needs wider production testing.

Missing / To Do

Sign in with Apple review.

Biometric login.

Full first-run onboarding.

Account deletion flow.

Email/phone change flows.

4. Customer Profile and Address Management

Completed

Customer profile page exists.

Current user profile loading works.

Reservation count is connected to real reservations.

My Reservations navigation works.

Customer address list and add-address screens are connected.

Payment methods screen is connected.

Preferences screen is connected.

History and favorites screen is connected.

Settings, KVKK, Terms, Help, and About screens exist.

Firestore-backed customer preferences/address infrastructure exists.

Partially Completed

Address edit/delete/default selection needs broader regression testing.

Payment methods remain UI-level without a real payment backend.

Some preferences still need end-to-end persistence verification.

Missing / To Do

Map-based address selection.

Customer profile photo update review.

Data export.

Account deletion.

Final decision on unused/mock customer profile screens.

5. Expert Profile and Provider Management

Completed

ExpertHomepage exists.

ExpertProfilePage exists.

ExpertListingsPage exists.

ExpertPortfolioPage exists.

Expert listing create/edit/delete flows exist.

Expert profile completion logic exists.

Verification document upload exists for identity front/back and certificates.

Admin can inspect verification documents.

Provider application moderation is implemented.

Admin can approve, reject, or request documents.

Admin notes and decision status are shown in expert UI.

Expert can resubmit after rejection or a document request.

Provider application history is stored and visible only to admins.

Provider dashboard, schedule, finance, stats, services, portfolio, and business profile screens are connected.

Real provider reservations are shown in the provider schedule.

Booked slots are represented in Firestore.

Duplicate provider/date/time reservations are prevented.

Provider application flow was manually tested end to end.

Partially Completed

Provider dashboard, finance, and statistics need deeper real-data verification.

Provider services/portfolio screens overlap with existing screens and need consolidation.

Provider profile contains sensitive and public data in the same Firestore document.

Missing / To Do

Move identity, tax, and banking fields to an admin/owner-only data structure.

Tighten provider profile read rules.

Add verification-document Storage rules review.

Consolidate duplicate provider screens.

Add provider availability exception/holiday management.

6. Service Search and Home Page

Completed

Customer homepage exists.

Services are listed from Firestore.

Search, filtering, favorites, and pagination exist.

LocationManager and SpeechRecognizer exist.

Service cards and service detail navigation exist.

Active-service pagination exists.

Service/provider scoring and filtering infrastructure exists.

Review/rating data can be reflected in provider/service presentation.

Partially Completed

Some filtering and scoring remain client-side.

Firestore ordering/index usage needs review.

Search ranking needs production data testing.

Missing / To Do

Map view for nearby providers.

Grid/list/map switch.

Stronger server-side search.

Distance/rating sorting validation.

Recommendation personalization.

Skeleton loading UI.

7. Service Detail Page

Completed

Service and provider details are shown.

Portfolio/gallery data is loaded.

Favorite toggle exists.

Apple Maps directions can be opened.

Message and reservation actions exist.

Provider reviews and rating information are integrated.

Review photos can be opened in a gallery.

Provider response content can be displayed.

Related provider services are loaded.

Partially Completed

Availability presentation can be clearer.

Certificate/document preview UX needs improvement.

Call/share actions are not fully standardized.

Missing / To Do

Call action.

Share action.

Availability indicator polish.

Certificate preview polish.

Richer provider service-area presentation.

8. Reservation System

Completed

Reservation model, repository, ViewModels, customer list, expert list, and detail page exist.

Customer can create and cancel reservations.

Expert can accept and reject reservations.

Rejection reason selection exists.

Reservation statuses include pending, accepted, rejected, cancelled, in-progress, completed, and no-show flows.

Reservation detail actions update status securely.

Customer and expert can open the related chat.

Date and time are selected separately.

Duplicate provider time slots are prevented.

Cancelled/rejected slots can be released and reused.

Provider calendar is connected to real reservations.

Booked days and time slots appear in the provider schedule.

Reservation status rules are versioned in the repository.

Reservation notifications use the FCM/Cloud Functions infrastructure.

Completed reservations can lead to the review flow.

Important customer/expert reservation flows were manually tested.

Partially Completed

Address selection during checkout needs final end-to-end review.

Reservation success/confirmation UX can be improved.

EventKit/Apple Calendar integration is not complete.

Multi-device concurrent slot tests should continue.

Missing / To Do

Payment step.

Apple Calendar/EventKit integration.

Reschedule flow.

Recurring reservations.

Cancellation/refund policy integration.

Automated end-to-end booking tests.

9. Messaging System

Completed

Conversation and ChatMessage models exist.

Message repository and ViewModels exist.

Conversation list and chat detail screens exist.

Real Firestore messages persist.

Text messaging works between customer and expert.

Service detail and reservation detail can open the correct conversation.

Nested conversation/message security rules are versioned.

Conversation read/unread state is stored and updated.

Multi-role messaging was manually tested.

FCM infrastructure can support message notifications.

Partially Completed

Read receipt UI can be clearer.

Message push delivery needs final multi-device/background testing.

Message UI is still basic.

Messaging is text-only.

Long chat pagination is not implemented.

Missing / To Do

Typing indicator.

Media attachments.

Message archive/mute/delete.

Conversation search.

Presence/online indicator.

Long-chat pagination.

Better read receipt UI.

Notification deep-link testing.

10. Notifications

Completed

Notification permission and settings UI exist.

Notification categories exist.

FCM token saving and refresh handling exist.

Foreground notification handling exists.

Cloud Functions push helper exists.

Reservation-related notification infrastructure exists.

Review moderation notifications exist.

Provider application decision notifications exist.

Firestore notification records are created for important admin actions.

Partially Completed

Notification preference toggles are not fully enforced by backend delivery.

Message push notifications need final background/multi-device verification.

In-app notification records exist, but a full notification center UX is not complete.

APNs production setup needs final review.

Missing / To Do

Full in-app notification center.

Read/unread notification UI.

Notification deep links for every type.

Retry/dead-letter strategy.

Connect all preferences to backend delivery.

Badge management.

Delivery/open analytics.

11. Payment System

Completed

Payment methods screen is connected from customer profile.

Partially Completed

Payment method UI exists.

Payment is not connected to reservation checkout.

No real payment backend/provider is integrated.

Missing / To Do

Payment provider decision.

Apple Pay setup.

Secure tokenization.

Reservation payment selection.

Payment summary.

Transaction model.

Receipt display.

Refund flow.

Payment security/compliance review.

12. Reviews and Ratings

Completed

Review model exists.

Review repository and provider review ViewModel exist.

Review submission is connected to completed reservations.

Overall and category ratings exist.

Written review validation exists.

Review photo upload exists.

Provider review list and rating summary exist.

Review sorting/filtering/statistics infrastructure exists.

Verified reservation review support exists.

One-review-per-reservation validation exists.

Provider response flow exists.

Helpful vote/count flow exists.

Review reporting flow exists.

Report categories and descriptions exist.

Admin review report queue exists.

Admin can dismiss a report or remove reported content.

Review moderation is executed through an admin-only callable Function.

Review moderation archive/history exists.

Review moderation notifications exist.

Review and moderation security rules are versioned.

Positive and negative security tests were performed manually.

Partially Completed

Review pagination and large-data performance need production testing.

Advanced spam/sentiment moderation is not implemented.

Provider response editing policy can be improved.

Missing / To Do

Automated review repository tests.

Automated moderation Function tests.

Advanced moderation tooling.

Review reminder scheduling.

Review export/reporting.

13. Settings and Preferences

Completed

Settings, Help, About, KVKK, Terms, Notification Preferences, and appearance settings exist.

Dynamic app version/build display exists.

Preferences screen is connected.

Password reset flow is connected.

Partially Completed

Legal content requires final legal review.

Notification preferences are not fully enforced by backend.

Language/localization coverage needs review.

Missing / To Do

Delete account.

Data export.

Clear cache.

Support/contact form.

Feedback/report-problem flow.

Final legal URLs/content.

Full localization audit.

14. Location and Map Features

Completed

LocationManager exists.

Reverse geocoding exists.

Apple Maps navigation shortcut exists.

Address screens exist.

Partially Completed

Location is used without a full map-based marketplace flow.

Address-to-reservation integration needs final validation.

Missing / To Do

Map-based provider search.

Map annotations.

Address autocomplete.

Map-based address picker.

Route preview.

Provider service area visualization.

15. Media Handling

Completed

PhotosPicker/image picker usage exists.

StorageUploadService exists.

Profile, listing, portfolio, review, certificate, and identity uploads exist.

Review photo gallery exists.

Partially Completed

Image compression is applied in some flows but is not standardized.

Cache/downsampling strategy needs review.

Sensitive verification documents need stronger access separation.

Missing / To Do

Thumbnail pipeline.

Shared image compression/downsampling service.

Media cache policy.

Chat media upload.

Verification document retention/deletion policy.

Storage emulator/security tests.

16. Security and Privacy

Completed

Firestore rules are versioned and deployed from the repository.

Conversations are limited to participants.

Message creation and read updates are restricted.

Reservation transitions and booked slots are rule-protected.

Reviews, reports, responses, and moderation archives have dedicated rules.

Admin custom claims protect admin Functions and admin-only collections.

Provider application moderation is performed through an admin-only callable Function.

Provider application history is admin-only.

Review moderation is performed through an admin-only callable Function.

Negative tests were performed for conversations, users, services, providers, reviews, and admin moderation flows.

Local GoogleService-Info.plist/signing differences are excluded from commits.

Partially Completed

Signed-in reads for service_providers expose too many fields.

users read access remains broader than ideal.

Storage security for identity/certificate files needs review.

Manual security tests are not automated.

Missing / To Do

Separate provider public profile from sensitive verification/banking/tax data.

Tighten service_providers read permissions.

Tighten users read permissions without breaking uniqueness checks.

Add Firebase emulator security tests.

Add account/data deletion flow.

Complete privacy labels and GDPR/KVKK review.

Add audit retention policy for admin history collections.

17. Admin and Moderation

Completed

Admin dashboard exists.

Admin access uses a Firebase custom claim.

Pending expert applications can be listed and inspected.

Identity and certificate links can be reviewed.

Admin can approve, reject, or request documents.

Admin note validation exists.

Provider application decisions are handled by a callable Function.

Provider application decision history exists.

Expert sees decision status and admin note.

Expert can update documents and resubmit.

Reported reviews can be listed.

Review reports can be dismissed or removed.

Review moderation is handled by a callable Function.

Review moderation history exists.

Admin-only Firestore read rules exist for history collections.

Provider and review moderation flows were manually tested.

Admin changes were committed and pushed.

Partially Completed

Admin lists need pagination/search/filter improvements for larger datasets.

Admin action audit views can be richer.

Push delivery needs broader real-device testing.

Missing / To Do

Admin user search/support tools.

Admin dashboard counts and metrics.

Admin role management UI.

Exportable audit logs.

Automated admin security tests.

Sensitive provider document isolation.

18. Analytics and Reporting

Completed

Provider dashboard and stats screens exist.

Review statistics infrastructure exists.

Reservation and provider data are available for real metrics.

Partially Completed

Provider dashboard/statistics require real-data validation.

Firebase Analytics custom events are not complete.

Revenue metrics cannot be final without payment integration.

Missing / To Do

Analytics event taxonomy.

Booking, message, search, review, and moderation events.

Real provider dashboard queries.

Revenue analytics after payment integration.

Crashlytics review.

Export/report generation.

19. Performance

Completed

Lazy containers and async/await are used.

Service pagination exists.

Review/provider lists use paged or limited queries in key areas.

Build and phone regression tests are performed after major changes.

Partially Completed

Firestore index/query optimization needs review.

Large review/message/admin history datasets need load testing.

Image handling needs standardization.

Missing / To Do

Instruments profiling.

Memory leak review.

Image downsampling.

Cache strategy.

Query/index audit.

Dashboard/statistics performance testing.

20. Testing

Completed

Manual phone tests cover:

Login/signup/OTP

Home/search/services/favorites

Customer and expert profiles

Reservation creation and status operations

Provider schedule/booked slots

Customer/expert messaging

Review submission and provider response

Helpful/report review flows

Admin review moderation

Admin provider application moderation

Provider document request/resubmit/approve

Admin moderation histories

Settings and notification permission

Important Firestore negative security tests were performed.

Build-test-commit workflow is used.

Partially Completed

Multi-device testing should continue.

Push notifications need background/terminated-state tests.

Regression testing remains manual.

Firebase rules/Functions tests are not automated.

Missing / To Do

Unit tests.

ViewModel tests.

Repository mock tests.

UI tests.

Firebase emulator rules tests.

Cloud Functions tests.

Automated booking tests.

Automated review/moderation tests.

Regression and smoke-test documents.

21. Deployment and App Store Preparation

Completed

Project builds locally.

GitHub branch/PR workflow is used.

Firebase rules and Functions can be deployed from the repository.

Local signing/plist differences are managed carefully.

Partially Completed

App version/build display exists.

Production APNs configuration needs final review.

Missing / To Do

TestFlight setup.

App Store screenshots.

Privacy policy URL.

Terms of service URL.

App metadata.

App icon/launch screen final review.

Version/build strategy.

Release notes.

Production Firebase environment checklist.
