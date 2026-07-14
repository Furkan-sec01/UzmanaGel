# Guide Implementation Checklist

This document tracks the implementation status of the iOS service-customer matching platform guide.

Status meanings:
- Completed: Implemented and tested or already available in the project.
- Partially Completed: Implemented partly, needs improvement, testing, or integration.
- Missing / To Do: Not implemented yet.
- Blocked: Waiting for Firebase Blaze, OTP, Apple Developer setup, or backend support.

---

## 1. Project Planning and Architecture

### Completed
- SwiftUI is used as the main UI framework.
- MVVM-style structure is used with View, ViewModel, Model, and Repository layers.
- Repository pattern is used for Firebase data access.
- Firebase Authentication is integrated.
- Cloud Firestore is integrated.
- Firebase Storage is integrated.
- NavigationStack is used in main flows.
- The project uses Git and GitHub branch / PR workflow.

### Partially Completed
- Project documentation is limited.
- Architecture is understandable but still needs cleanup and standardization.
- Some Firebase Security Rules were updated manually in Firebase Console.

### Missing / To Do
- Add a detailed README architecture section.
- Add feature status documentation.
- Add Firebase rules versioning into the repository.
- Add setup instructions for new developers.

---

## 2. Firebase and Backend Setup

### Completed
- Firebase Auth is connected.
- Firestore is connected.
- Firebase Storage is connected.
- GoogleService-Info.plist is added.
- Cloud Functions folder exists in the repository.

### Partially Completed
- Firestore Security Rules were improved for users, services, service providers, conversations, messages, and reservations.
- Reservation rules were updated manually in Firebase Console.
- OTP / Phone Auth flow exists but cannot be fully tested yet.

### Blocked
- Firebase Blaze plan is needed for real phone OTP testing.

### Missing / To Do
- Move current Firestore Rules into repository.
- Review Cloud Functions.
- Check Firebase Analytics setup.
- Check Firebase Crashlytics setup.
- Check Firebase Remote Config setup.
- Check Firebase Cloud Messaging setup.

---

## 3. Authentication and User Management

### Completed
- Email/password login exists.
- User signup flow exists.
- Session handling exists through SessionViewModel.
- User role handling exists.
- Login attempt tracking exists.
- Google login flow exists.

### Partially Completed
- Expert signup flow exists but OTP testing is blocked.
- Phone duplicate check was adjusted after security rule changes.
- Profile loading was improved for current user data.

### Blocked
- Expert registration live test is blocked by Firebase Blaze / OTP issue.

### Missing / To Do
- Sign in with Apple review.
- Password reset flow review.
- Email verification flow review.
- Biometric login.
- Full onboarding flow.
- User type selection onboarding improvement.

---

## 4. Customer Profile and Address Management

### Completed
- Customer profile page exists.
- Current user profile loading was fixed.
- Address-related work was added by Baran and should be tracked as part of profile management.
- Settings page exists.
- KVKK / privacy page exists.

### Partially Completed
- Address management should be tested end-to-end.
- Profile edit UX can be improved.
- App version / legal links need review.

### Missing / To Do
- Multiple saved addresses flow review.
- Default address selection.
- Address edit/delete tests.
- Map-based address selection.
- Profile photo update review.
- Account deletion flow.

---

## 5. Expert Profile and Provider Management

### Completed
- ExpertHomepage exists.
- ExpertProfilePage exists.
- ExpertListingsPage exists.
- ExpertPortfolioPage exists.
- Expert listing creation exists.
- Expert profile completion logic exists.
- Expert can publish listings.
- Storage upload service supports expert/listing images.

### Partially Completed
- Expert dashboard concept exists in the guide, but current project mainly uses ExpertHomepage.
- Expert reservation listing screen was added at build level.
- Expert live flows need Blaze/OTP testing.

### Missing / To Do
- Full expert dashboard statistics.
- Availability toggle.
- Working calendar.
- Today’s appointments dashboard.
- Earnings/statistics cards.
- Expert accept/reject reservation actions.
- Expert-side reservation detail page.

---

## 6. Service Search and Home Page

### Completed
- Customer Homepage exists.
- Services are listed.
- Search/filter logic exists.
- Favorites exist.
- LocationManager exists.
- SpeechRecognizer exists.
- Service detail page exists.
- Service cards and detail navigation exist.
- Pagination was added for active services.

### Partially Completed
- Filtering is mostly client-side.
- Pagination works but can be improved with better Firestore ordering/indexes.
- Search can be improved with better Firestore query support.

### Missing / To Do
- Map view for nearby providers.
- Grid/list/map view switch.
- Advanced filters.
- Rating-based sorting.
- Distance-based sorting refinement.
- Provider recommendation algorithm.
- Skeleton loading UI.

---

## 7. Service Detail Page

### Completed
- Service detail page exists.
- Provider details are shown.
- Portfolio/gallery data is loaded.
- Favorite toggle exists.
- Apple Maps direction opening exists.
- Message button exists.
- Reservation button was added.
- ReservationCreateSheet is connected.

### Partially Completed
- Provider services filtering was improved.
- Detail page UI can still be improved.
- Chat and reservation shortcuts exist but can be more integrated.

### Missing / To Do
- Reviews section.
- Rating breakdown.
- Call button.
- Share button.
- Fullscreen image gallery.
- Certificate preview.
- Availability indicator.

---

## 8. Reservation System

### Completed
- Reservation model was added.
- ReservationStatus enum was added.
- ReservationRepository was added.
- ReservationViewModel was added.
- ReservationCreateSheet was added.
- ServiceDetailPage can create a reservation.
- Firestore creates pending reservations.
- MyReservationsViewModel was added.
- MyReservationsPage was added.
- Active / Past / Cancelled filters were added.
- Customer can cancel active reservations.
- Reservation detail page was added.
- SideMenuSheet includes My Reservations.
- ExpertReservationsViewModel was added.
- ExpertReservationsPage was added.
- ExpertHomepage links to incoming reservations.
- Customer-side reservation create/list/cancel flow was tested.
- Expert-side incoming reservations page was tested.
- Expert can accept pending reservations.
- Expert can reject pending reservations.
- Firestore reservation rules were updated manually in Firebase Console for customer cancel and expert accept/reject.
- Expert reservation list includes a View Details action.
- Reservation detail page includes a Send Message shortcut.
- Customer can send a message from reservation detail.
- Expert can send a message from reservation detail.
- Customer can cancel pending/accepted reservations from reservation detail.
- Expert can accept/reject pending reservations from reservation detail.
- Reservation detail status updates locally after actions.
- Expert reservation list refreshes after detail status changes.

### Partially Completed
- Reservation system is now stronger than MVP-level, but still not full guide-level.
- Status transitions exist for pending, accepted, rejected, and cancelled, but there is no completed flow yet.
- Chat shortcut exists, but notification integration is not added yet.
- Firestore reservation rules were updated manually, but they are not versioned in the repository yet.

### Blocked
- No current blocker for basic reservation create/cancel/accept/reject/chat flows.
- Real phone number OTP may still be temporarily throttled after repeated attempts, but Firebase test phone numbers work.

### Missing / To Do
- Reject reason selection.
- Reservation status transition validation as a central helper/service.
- Reservation detail timeline.
- Address selection during reservation.
- Time slot selection.
- Provider availability calendar.
- Payment step.
- Reservation success screen.
- Calendar integration.
- Reservation notification flow.
- Map/navigation shortcut from reservation detail.
- Completion flow after service is done.
- Customer review/rating flow after completed reservation.

## 9. Messaging

### Completed
- Conversation model was added.
- ChatMessage model was added.
- MessageRepository was added.
- MessageViewModel was added.
- ChatDetailViewModel was added.
- MessagesPage was added.
- ChatDetailPage was added.
- Firestore-based real messaging was implemented.
- Customer can start a conversation from ServiceDetailPage.
- Existing conversations are reused with deterministic conversation IDs.
- Messages are stored under conversations/{conversationId}/messages.
- Conversation list shows last message and unread count.
- ChatDetailPage listens to messages in real time.
- Message sending works between customer and expert.
- Mark-as-read logic was added.
- Firestore conversation/message rules were updated manually in Firebase Console.
- Messaging rules now use nested conversations/{conversationId}/messages/{messageId}.
- ExpertHomepage includes a Messages shortcut.
- Expert side menu includes Messages.
- Customer can send a message from reservation detail.
- Expert can send a message from reservation detail.
- Customer-to-expert and expert-to-customer messaging were tested successfully.

### Partially Completed
- Basic read/unread logic exists, but the UI does not clearly show read receipts yet.
- Messaging works for text messages only.
- Firestore rules were updated manually, but they are not versioned in the repository yet.
- Message list works, but pagination is not added yet.

### Blocked
- No current blocker for basic customer-expert messaging.
- Push notification integration is not implemented yet.

### Missing / To Do
- Push notifications for new messages.
- Typing indicator.
- Read receipt UI.
- Message pagination.
- Conversation search.
- Media/image attachment support.
- Message delete/archive/mute actions.
- Better empty state and loading state.
- Support/contact conversation flow.
- Notification preferences integration with message notifications.

## 10. Notifications

### Completed
- No complete notification system yet.

### Partially Completed
- Notification-related Firebase/FCM may be present in project dependencies but needs verification.

### Missing / To Do
- Push notification permission request.
- FCM token saving.
- Reservation notification.
- Message notification.
- Provider accept/reject notification.
- In-app notification center.
- Notification preferences.

---

## 11. Payment System

### Completed
- No full payment flow implemented yet.

### Missing / To Do
- Apple Pay setup.
- Payment method selection.
- Payment summary.
- Transaction model.
- Refund flow.
- Receipt display.
- Payment security review.

---

## 12. Reviews and Ratings

### Completed
- No full review system implemented yet.

### Missing / To Do
- Review model.
- Review submission after completed reservation.
- Rating UI.
- Provider review list.
- Review validation.
- Provider response to review.
- Report review flow.

---

## 13. Settings / Preferences

### Completed
- SettingsPage was added.
- SideMenuSheet links to SettingsPage.
- Appearance selection was added.
- Selected appearance is stored with AppStorage.
- Notification toggle exists.
- NotificationPreferencesPage was added.
- iOS notification permission status/check was added.
- Notification categories were added:
- Reservation notifications.
- Message notifications.
- System notifications.
- Marketing notifications.
- KVKK / Privacy page is linked from Settings.
- Terms of Service page was added.
- HelpPage exists.
- HelpPage was expanded with more FAQ items.
- AboutPage exists.
- AboutPage now shows dynamic version and build number.
- Settings, Help, About, KVKK, Terms, and Notification Preferences screens build and open successfully.

### Partially Completed
- Notification preferences are currently stored locally with AppStorage.
- iOS notification permission check exists, but real push notification backend integration is not added yet.
- Legal pages exist, but final legal text should be reviewed before production.
- Help page has basic FAQ content, but no real support/contact form yet.

### Blocked
- No current blocker for local settings features.
- Real notification delivery depends on future Firebase Cloud Messaging / APNs setup.

### Missing / To Do
- Real push notification backend integration.
- Save notification preferences to Firestore if needed.
- Language selection.
- Account deletion flow.
- Data export / privacy request flow.
- Support/contact form.
- App feedback/report problem flow.
- Cache clear option.
- More detailed privacy settings.
- Terms/KVKK final legal review.

## 14. Location and Map Features

### Completed
- LocationManager exists.
- Reverse geocoding exists in service detail logic.
- Apple Maps direction opening exists.
- Address-related work exists and needs end-to-end verification.

### Partially Completed
- Location is used but not a full map-based flow.

### Missing / To Do
- Map-based provider search.
- Map annotations.
- Address search autocomplete.
- Map-based address selection.
- Route preview.
- Provider service area visualization.

---

## 15. Media Handling

### Completed
- Image picker usage exists.
- StorageUploadService exists.
- Listing image upload exists.
- Expert portfolio image upload exists.
- Certificate / verification document upload support exists.

### Partially Completed
- Media upload exists but can be improved.

### Missing / To Do
- Image compression review.
- Thumbnail generation.
- Fullscreen gallery.
- Media cache.
- Chat media upload.
- Review photo upload.

---

## 16. Security and Privacy

### Completed
- Firestore rules were tightened from public rules.
- Conversations are limited to participants.
- Message writes are restricted to sender.
- Services and service providers use ownership-based write rules.
- Reservation create/cancel rules were added manually.
- Negative security tests were performed for conversations, users, services, and service providers.

### Partially Completed
- Users read access is still broad for phone duplicate check.
- Firestore rules are not fully versioned in repo.
- Reservation rules should be reviewed by the team.

### Missing / To Do
- Move final Firestore rules into repo.
- Admin role handling.
- More negative tests.
- Storage security rules review.
- App privacy labels.
- Data deletion / GDPR flow.

---

## 17. Analytics and Reporting

### Completed
- No full analytics dashboard implemented yet.

### Missing / To Do
- Firebase Analytics events.
- Booking creation event.
- Message sent event.
- Search event.
- Provider dashboard metrics.
- Reservation statistics.
- Crashlytics integration check.

---

## 18. Performance

### Completed
- Lazy containers are used in several screens.
- Pagination was added for services.
- Async/await is used.

### Partially Completed
- Some screens still need performance review.
- Firestore query optimization needs review.

### Missing / To Do
- Firestore indexes review.
- Image downsampling.
- Cache strategy.
- Instruments performance test.
- Memory leak review.

---

## 19. Testing

### Completed
- Manual phone testing was done for important flows:
  - Login
  - Home
  - Services
  - Messaging
  - Favorites
  - Reservation create/list/cancel
  - Settings navigation

### Partially Completed
- Security negative tests were performed manually.

### Missing / To Do
- Unit tests.
- ViewModel tests.
- Repository mock tests.
- UI tests.
- End-to-end booking tests.
- Multi-device testing.
- Regression checklist.

---

## 20. Deployment and App Store Preparation

### Completed
- Project builds locally.
- GitHub PR workflow is used.

### Missing / To Do
- TestFlight setup.
- App Store screenshots.
- Privacy policy URL.
- Terms of service URL.
- App metadata.
- App icon / launch screen final review.
- App version/build number strategy.
- Release notes.