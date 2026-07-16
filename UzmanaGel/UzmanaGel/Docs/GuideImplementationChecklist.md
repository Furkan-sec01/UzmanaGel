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
- Feature branches and pull requests are used for safe development.

### Partially Completed
- Project documentation is limited.
- Architecture is understandable but still needs cleanup and standardization.
- Some Firebase Security Rules were updated manually in Firebase Console.
- New provider/customer feature screens were integrated, but some still need real data review.

### Missing / To Do
- Add a detailed README architecture section.
- Add feature status documentation.
- Add Firebase rules versioning into the repository.
- Add setup instructions for new developers.
- Add a clear feature ownership / module documentation section.

---

## 2. Firebase and Backend Setup

### Completed
- Firebase Auth is connected.
- Firestore is connected.
- Firebase Storage is connected.
- GoogleService-Info.plist is added.
- Cloud Functions folder exists in the repository.
- Firebase project was upgraded to Blaze plan.
- Phone Auth / OTP flow was tested successfully with Firebase test phone numbers.
- Firestore Security Rules were improved for users, services, service providers, conversations, messages, and reservations.
- Reservation and conversation/message rules were updated manually in Firebase Console.

### Partially Completed
- Real phone number OTP may still be temporarily throttled after repeated attempts.
- Firestore Rules are improved but still not versioned in the repository.
- Firebase backend setup works for current tested flows, but production notification/payment setup is not complete.

### Missing / To Do
- Move current Firestore Rules into repository.
- Review Cloud Functions.
- Check Firebase Analytics setup.
- Check Firebase Crashlytics setup.
- Check Firebase Remote Config setup.
- Check Firebase Cloud Messaging setup.
- Review APNs setup for production Phone Auth / push notifications.

---

## 3. Authentication and User Management

### Completed
- Email/password login exists.
- User signup flow exists.
- Session handling exists through SessionViewModel.
- User role handling exists.
- Login attempt tracking exists.
- Google login flow exists.
- Phone Auth / OTP flow works with Firebase test phone numbers.
- Expert signup flow was tested with OTP.
- Expert account can reach ExpertHomepage after manual Firestore approval.
- Forgot password flow was improved.
- Forgot password page pre-fills email from LoginPage.
- Reset password email flow was tested successfully.
- Profile loading was improved for current user data.

### Partially Completed
- Real phone number OTP may still be temporarily throttled.
- Expert approval is currently manual through Firestore.
- Email verification flow exists but needs more review.
- User type onboarding can be improved.

### Missing / To Do
- Sign in with Apple review.
- Email verification improvements.
- Biometric login.
- Full onboarding flow.
- User type selection onboarding improvement.
- Admin approval panel for expert applications.

---

## 4. Customer Profile and Address Management

### Completed
- Customer profile page exists.
- Current user profile loading was fixed.
- Old “Orders” logic was removed from ProfilePage.
- Profile reservation count is connected to real reservations.
- My Reservations card opens MyReservationsPage.
- Reservation row under History & Favorites works.
- Baran’s CustomerAddressListView was connected from ProfilePage.
- AddAddressView is reachable from CustomerAddressListView.
- Baran’s PaymentMethodsView was connected from ProfilePage.
- Baran’s PreferencesView was connected from ProfilePage.
- Baran’s HistoryFavoritesView was connected from ProfilePage.
- Settings page exists.
- KVKK / privacy page exists.

### Partially Completed
- Address management screens are connected but still use the current implementation level from Baran’s feature files.
- Payment methods screen is connected but full payment backend is not implemented.
- Preferences screen is connected but may still need real backend integration depending on requirements.
- Existing real ProfilePage was kept instead of replacing it with Baran’s mock-style CustomerProfileView.

### Missing / To Do
- Multiple saved addresses flow review.
- Default address selection.
- Address edit/delete tests.
- Map-based address selection.
- Profile photo update review.
- Account deletion flow.
- Decide whether CustomerProfileView should stay unused or be merged into the real ProfilePage.

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
- Baran’s ProviderDashboardView was connected from ExpertHomepage.
- Baran’s ScheduleView was connected from ExpertHomepage.
- Baran’s FinanceView was connected from ExpertHomepage.
- Baran’s ProviderStatsView was connected from ExpertHomepage.
- Baran’s ProviderServicesView was connected from ExpertHomepage.
- Baran’s PortfolioView was connected from ExpertHomepage.
- Baran’s EditBusinessProfileView was connected from ExpertHomepage.
- Expert feature screens were standardized with full-screen presentation and a single “Kapat” action.
- NavigationPath crash was avoided by not pushing Baran’s new provider screens into the existing String navigation path.

### Partially Completed
- Baran’s provider screens are connected and open correctly, but many of them still use mock/service-level data.
- Expert dashboard, finance, stats, services, portfolio and business profile screens need real data integration review.
- Existing expert profile/listing/reservation/message flows still work after integration.

### Missing / To Do
- Connect provider dashboard metrics to real Firestore data.
- Connect finance screen to real payment/earnings data.
- Connect provider stats to real reservations, ratings and revenue.
- Review ProviderServicesView against existing ExpertListingsPage.
- Review PortfolioView against existing ExpertPortfolioPage.
- Availability toggle.
- Working calendar real availability integration.
- Today’s appointments dashboard with real reservations.

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
- Expert-side incoming reservations page was tested after Blaze/OTP issue was solved.
- Expert can accept pending reservations.
- Expert can reject pending reservations.
- Reservation status updates correctly after expert accept/reject.
- Firestore reservation rules were updated manually in Firebase Console.
- Customer can cancel pending/accepted reservations from reservation detail.
- Expert can accept/reject pending reservations from reservation detail.
- Reservation detail page includes a Send Message shortcut.
- Customer and expert can open the related chat from reservation detail.
- Expert reservation list includes a View Details action.
- Expert reservation list refreshes after detail status changes.

### Partially Completed
- Reservation system is stronger than MVP-level but still not full guide-level.
- Status transitions exist for pending, accepted, rejected and cancelled, but there is no completed flow yet.
- Firestore reservation rules were updated manually but are not versioned in the repository.
- Calendar/schedule screen exists through Baran’s provider feature, but it is not yet connected to real reservation availability.

### Missing / To Do
- Reject reason selection.
- Reservation status transition validation as a central helper/service.
- Reservation detail timeline.
- Address selection during reservation.
- Time slot selection.
- Real provider availability calendar.
- Payment step.
- Reservation success screen.
- Calendar integration with real reservations.
- Reservation notification flow.
- Map/navigation shortcut from reservation detail.
- Completion flow after service is done.
- Customer review/rating flow after completed reservation.

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
- Messaging rules now use nested conversations/{conversationId}/messages/{messageId}.
- ExpertHomepage includes Messages access.
- Expert side menu includes Messages access.
- Customer can send a message from reservation detail.
- Expert can send a message from reservation detail.
- Customer-to-expert and expert-to-customer messaging were tested successfully.

### Partially Completed
- Read/unread logic exists but the UI does not clearly show read receipts yet.
- Message UI is basic.
- Messaging works for text messages only.
- Firestore rules were updated manually but are not versioned in the repository.
- Message pagination is not added yet.

### Missing / To Do
- Push notifications for new messages.
- Typing indicator.
- Media attachments.
- Message delete/archive/mute.
- Search conversations.
- Online/presence indicator.
- Pagination for long chats.
- Better unread/read receipt UI.

---

## 10. Notifications

### Completed
- NotificationPreferencesPage was added.
- iOS notification permission status/check was added.
- Notification categories were added:
  - Reservation notifications.
  - Message notifications.
  - System notifications.
  - Marketing notifications.
- User can request/check notification permission from the app.
- Notification preferences screen opens from SettingsPage.

### Partially Completed
- Notification preferences are currently local/UI-level.
- Real push notification delivery is not implemented yet.
- Firebase Cloud Messaging / APNs setup still needs production review.

### Missing / To Do
- FCM token saving.
- Reservation notification.
- Message notification.
- Provider accept/reject notification.
- In-app notification center.
- Connect notification preferences to real notification delivery.
- Store notification preferences in Firestore if needed.

---

## 11. Payment System

### Completed
- Baran’s PaymentMethodsView was connected from ProfilePage.
- Payment methods screen can be opened from the customer profile flow.

### Partially Completed
- Payment method UI exists at feature-screen level.
- Full payment backend is not implemented yet.
- Payment flow is not connected to reservation checkout yet.

### Missing / To Do
- Apple Pay setup.
- Payment method selection for reservation flow.
- Payment summary.
- Transaction model.
- Refund flow.
- Receipt display.
- Payment security review.
- Real payment provider integration.

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
- NotificationPreferencesPage was added.
- TermsOfServicePage was added.
- AboutPage now shows dynamic version and build number.
- HelpPage was expanded with more FAQ items.
- Forgot password/reset password flow was improved.
- Settings, Help, About, KVKK, Terms and Notification Preferences screens build and open successfully.
- Baran’s PreferencesView was connected from ProfilePage.
- Rezervasyon, Şifre Değiştirme ve Konum Seçici ekranları Türkçe ve İngilizce dillerini destekleyecek şekilde yerelleştirildi (Language Manager entegrasyonu).

### Partially Completed
- Legal/support pages are still basic and need final legal review.
- Notification preferences exist but real push notification backend is not connected.
- PreferencesView is connected but needs review for real data persistence.

### Missing / To Do
- Real push notification backend integration.
- Privacy preferences.
- Delete account.
- Data export.
- Clear cache.
- Support/contact form.
- App feedback/report problem flow.
- Final Terms/KVKK legal review.

---

## 14. Location and Map Features

### Completed
- LocationManager exists.
- Reverse geocoding exists in service detail logic.
- Apple Maps direction opening exists.
- Address-related work exists and needs end-to-end verification.
- Baran’s CustomerAddressListView was connected from ProfilePage.
- AddAddressView is reachable from CustomerAddressListView.

### Partially Completed
- Location is used but not a full map-based flow.
- Address screens exist, but map-based selection is not implemented yet.

### Missing / To Do
- Map-based provider search.
- Map annotations.
- Address search autocomplete.
- Map-based address selection.
- Route preview.
- Provider service area visualization.
- Default address integration with reservation flow.

---

## 15. Media Handling

### Completed
- Image picker usage exists.
- StorageUploadService exists.
- Listing image upload exists.
- Expert portfolio image upload exists.
- Certificate / verification document upload support exists.
- Baran’s provider portfolio screen was connected from ExpertHomepage.

### Partially Completed
- Media upload exists but can be improved.
- Portfolio-related screens need review against existing ExpertPortfolioPage.
- Chat media upload is not implemented yet.

### Missing / To Do
- Image compression review.
- Thumbnail generation.
- Fullscreen gallery.
- Media cache.
- Chat media upload.
- Review photo upload.
- Portfolio screen real data integration review.

---

## 16. Security and Privacy

### Completed
- Firestore rules were tightened from public rules.
- Conversations are limited to participants.
- Message writes are restricted to sender.
- Services and service providers use ownership-based write rules.
- Reservation create/cancel rules were added manually.
- Reservation accept/reject rules were added manually.
- Negative security tests were performed for conversations, users, services, and service providers.
- Local GoogleService-Info.plist / signing / bundle ID changes were excluded from commits.

### Partially Completed
- Users read access is still broad for phone duplicate check.
- Firestore rules are not fully versioned in repo.
- Reservation and conversation/message rules should be reviewed by the team.
- Storage security rules still need review.

### Missing / To Do
- Move final Firestore rules into repo.
- Admin role handling.
- More negative tests.
- Storage security rules review.
- App privacy labels.
- Data deletion / GDPR flow.
- Account deletion flow.

---

## 17. Analytics and Reporting

### Completed
- Baran’s ProviderDashboardView was connected from ExpertHomepage.
- Baran’s ProviderStatsView was connected from ExpertHomepage.
- Provider dashboard/statistics screens can be opened from the expert side.

### Partially Completed
- Provider dashboard and stats screens currently need real data integration review.
- No complete Firebase Analytics event system exists yet.
- Reporting screens exist at UI/feature level but are not fully connected to production metrics.

### Missing / To Do
- Firebase Analytics events.
- Booking creation event.
- Message sent event.
- Search event.
- Provider dashboard metrics from real data.
- Reservation statistics from real data.
- Revenue/statistics calculation.
- Crashlytics integration check.

---

## 18. Performance

### Completed
- Lazy containers are used in several screens.
- Pagination was added for services.
- Async/await is used.
- Build and phone tests were completed after provider/customer feature screen integration.

### Partially Completed
- Some screens still need performance review.
- Firestore query optimization needs review.
- Baran’s newly connected feature screens should be reviewed for performance with real data.

### Missing / To Do
- Firestore indexes review.
- Image downsampling.
- Cache strategy.
- Instruments performance test.
- Memory leak review.
- Performance test for provider dashboard/statistics screens.

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
  - Reservation detail actions
  - Expert accept/reject reservation
  - Customer-to-expert messaging
  - Expert-to-customer messaging
  - Settings navigation
  - Notification permission screen
  - Password reset email flow
  - Expert provider screens integrated from Baran’s work
  - Customer profile feature screens integrated from Baran’s work
- Security negative tests were performed manually for important Firestore access cases.
- Build and phone tests were completed after provider/customer feature screen integration.
- Existing expert screens were tested after new full-screen presentation changes.
- Customer profile menu links were tested after connecting Baran’s customer feature screens.

### Partially Completed
- Multi-device and multi-user testing should continue.
- Baran’s provider/customer feature screens open correctly, but real data integration still needs separate testing.
- Security rules were manually tested but should be versioned and reviewed.
- Regression testing should continue after each merge.

### Missing / To Do
- Unit tests.
- ViewModel tests.
- Repository mock tests.
- UI tests.
- End-to-end booking tests.
- Multi-device testing.
- Regression checklist.
- Automated smoke test checklist.

---

## 20. Deployment and App Store Preparation

### Completed
- Project builds locally.
- GitHub PR workflow is used.
- Feature branches are used before merging into main.

### Partially Completed
- App version/build display was improved in AboutPage.
- Local development signing/plist differences are managed carefully and excluded from commits.

### Missing / To Do
- TestFlight setup.
- App Store screenshots.
- Privacy policy URL.
- Terms of service URL.
- App metadata.
- App icon / launch screen final review.
- App version/build number strategy.
- Release notes.
