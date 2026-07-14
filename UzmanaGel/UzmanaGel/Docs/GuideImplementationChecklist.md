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

### Partially Completed
- Expert-side reservation page builds, but live test is pending.
- Reservation system is currently MVP-level, not full guide-level.

### Blocked
- Expert-side live testing is blocked until Blaze / OTP issue is solved.

### Missing / To Do
- Expert accept reservation.
- Expert reject reservation.
- Reject reason selection.
- Reservation status transition validation.
- Reservation detail timeline.
- Address selection during reservation.
- Time slot selection.
- Provider availability calendar.
- Payment step.
- Reservation success screen.
- Calendar integration.
- Reservation notification flow.
- Chat shortcut from reservation detail.
- Map/navigation shortcut from reservation detail.

---

## 9. Messaging System

### Completed
- Conversation model exists.
- ChatMessage model exists.
- MessageRepository exists.
- MessageViewModel exists.
- ChatDetailViewModel exists.
- MessagesPage exists.
- ChatDetailPage exists.
- ServiceDetailPage can start a conversation.
- Real Firestore messages are saved.
- Conversations list shows last message.
- Message persistence was tested.
- Conversation security rules were improved.

### Partially Completed
- Read/unread logic exists but needs more real multi-user testing.
- Message UI is basic.

### Missing / To Do
- Push notifications for new messages.
- Typing indicator.
- Media attachments.
- Message delete/archive/mute.
- Search conversations.
- Online/presence indicator.
- Pagination for long chats.

---

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

## 13. Settings and Preferences

### Completed
- SettingsPage exists.
- HelpPage exists.
- AboutPage exists.
- Theme / appearance setting exists.
- KVKK page exists.
- Side menu navigation was improved.

### Partially Completed
- Legal/support pages are basic.
- Settings structure can be expanded.

### Missing / To Do
- Notification preferences.
- Privacy preferences.
- Language settings.
- App version display.
- Delete account.
- Data export.
- Clear cache.

---

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