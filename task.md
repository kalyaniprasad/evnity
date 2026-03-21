# Flutter Firebase Integration Task Breakdown

- [x] Inspect project structure and existing codebase
- [x] Check and update [pubspec.yaml](file:///c:/Users/prasa/OneDrive/Desktop/FLUTTER_PROJECT/evnity/Evnity/pubspec.yaml) with required dependencies
- [x] **1. **User Profile Management**
   - [x] Create [UserRepository](file:///c:/Users/prasa/OneDrive/Desktop/FLUTTER_PROJECT/evnity/Evnity/lib/core/repositories/user_repository.dart#5-88) for Firestore CRUD operations (users/clubs).
   - [x] Update [StudentProfileEditNotifier](file:///c:/Users/prasa/OneDrive/Desktop/FLUTTER_PROJECT/evnity/Evnity/lib/core/providers/student_providers.dart#313-355) to push edits to Firestore via [UserRepository](file:///c:/Users/prasa/OneDrive/Desktop/FLUTTER_PROJECT/evnity/Evnity/lib/core/repositories/user_repository.dart#5-88).
   - [x] Update [CurrentUserNotifier](file:///c:/Users/prasa/OneDrive/Desktop/FLUTTER_PROJECT/evnity/Evnity/lib/core/providers/student_providers.dart#122-179) to fetch user profiles dynamically from Firestore instead of mock data.
   - [x] Ensure profile UI updates immediately upon save.

- [x] **2. Event Registration**
   - [x] Create [EventRepository](file:///c:/Users/prasa/OneDrive/Desktop/FLUTTER_PROJECT/evnity/Evnity/lib/core/repositories/event_repository.dart#5-137) to handle event and registration data.
   - [x] Update registration logic to write to `registrations` subcollection and update user's `registeredEventIds` via transactions.
   - [x] Update [EventDetailScreen](file:///c:/Users/prasa/OneDrive/Desktop/FLUTTER_PROJECT/evnity/Evnity/lib/features/student/event_detail/screens/event_detail_screen.dart#7-182) to correctly read current user registration status using `AsyncValue`.
- [x] **3. **Notification System**
   - [x] Fix notification icon in student home screen AppBar
   - [x] Create Notification Screen
   - [x] Implement [NotificationRepository](file:///c:/Users/prasa/OneDrive/Desktop/FLUTTER_PROJECT/evnity/Evnity/lib/core/repositories/notification_repository.dart#4-81) for mapping backend to UI.
   - [x] Replace mock data with real notifications fetched from Firestore.
- [x] **4. Event Discussion Chat**
    - [x] Implement chat UI for events
    - [x] Integrate Firebase Realtime Database for event-specific chat rooms
    - [x] Update messages in real-time
- [x] **5-9. Club Event Creation & Cloudinary Integration**
    - [x] Fix "Add Event" button navigation in Club panel
    - [x] Implement image selection using `image_picker`
    - [x] Implement Cloudinary image upload using HTTP
    - [x] Store event data in Firestore (`events` collection)
- [x] **10-11. Replace Mock Data & CRUD for Users/Clubs**
    - [x] Remove mock data from events, profiles, clubs
    - [x] Fetch real data from Firebase
- [x] **12. Validation and Error Handling**
    - [x] Add form validations
    - [x] Add loading indicators and error feedback
- [x] **14. Architecture Refactoring**
    - [x] Ensure clean architecture (models, services, providers, screens, widgets)

## Recent Bug Fixes & Feature Requests
- [x] Fix Discussion Chat infinite loading (check Realtime DB integration)
- [x] Direct user to create Firestore composite index for Events query
- [x] Fix blank screen when attempting to add an event in Club app
- [x] Build Event Registration Screen to collect required fields (currently registers automatically)
- [x] Fix Profile Screen showing mock data instead of null/empty for newly registered users/clubs
- [ ] Fix blank screen that appears IMMEDIATELY AFTER a club successfully creates an event
- [ ] Connect Club Dashboard (Home Screen) to use real Firebase profile data instead of hardcoded 'CodeCraft Club'
- [ ] Connect Club Dashboard to use real Firebase profile data instead of hardcoded 'CodeCraft Club'
