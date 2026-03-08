PROJECT OVERVIEW

Create a modern, production-ready Flutter mobile application named:

Evnity – Campus Event & Community Hub

This app is a centralized platform where:

Students discover and register for campus events

Clubs create and manage events

Students and clubs interact in event-specific discussions

⚠️ Admin panel will be built separately in React (DO NOT build admin in this mobile app).

IMPORTANT

This version must:

Build complete UI and app structure first

Use mock/local data models

Not include backend logic

Be fully structured and ready for Supabase integration in Phase 2

DEVELOPMENT APPROACH

Follow this order strictly:

Build complete UI first (no backend logic).

Use mock/local data models.

Structure app in scalable architecture.

Use Riverpod (latest stable version).

Maintain clean folder structure.

Keep architecture ready for Supabase integration.

EXPECTED PROJECT STRUCTURE

Follow scalable feature-first architecture similar to:

lib/
 ├── core/
 │    ├── theme/
 │    ├── constants/
 │    ├── router/
 │
 ├── features/
 │    ├── auth/
 │    ├── student/
 │    ├── club/
 │    ├── shared/
 │
 ├── models/
 ├── providers/
 ├── widgets/
 └── main.dart

Requirements:

Use Riverpod providers per feature.

Keep UI and logic separated.

Prepare repository layer for future API integration.

Mock data must be easily replaceable with Supabase services later.

USER ROLES

This mobile app supports:

Student

Club Organizer

(Admin panel is web-based and excluded from this build.)

COMPLETE UI FLOW TO BUILD
1️⃣ Onboarding Flow (3 Screens)

Create three onboarding screens:

Screen 1:

Title: Discover Campus Events

Illustration placeholder

Subtitle text

Next button

Screen 2:

Title: Connect with Clubs

Description

Illustration placeholder

Next button

Screen 3:

Title: Stay Updated in Real-Time

Description

Get Started button

Add:

Smooth page indicator

Minimal modern layout

2️⃣ ROLE SELECTION FLOW (FIRST SCREEN AFTER ONBOARDING)

Before login, user must select:

Continue as:

Student

Club Organizer

After selecting role → navigate to respective login screen.

This ensures clear separation of student and club flow.

AUTHENTICATION FLOW (ROLE-BASED)

⚠️ No real authentication logic yet.
Simulate successful login using mock logic.

Student Login Screen

Fields:

College Email

Password

Buttons:

Login

Create Account

Forgot Password

Club Login Screen

Fields:

Club Email

Password

Buttons:

Login

Create Account

Forgot Password

STUDENT APP FLOW

After login → Student Dashboard

Bottom Navigation:

Home

Search

Notifications

Profile

Home Screen

Scrollable event feed

Card-based event UI

Event card includes:

Poster image

Title

Club name

Date

Category tag

Tap → Event Details Screen

Search Screen

Search bar

Category filter chips

List results (Events + Clubs)

Event Details Screen

Sections:

Poster

Title

Description

Date & Venue

Register button

Discussion tab

Event Discussion Screen

Chat-style UI:

Messages

Input field

Send button

Student alias display

Notifications Screen

Event update cards

Reminder UI

Timeline-style layout

Profile Screen

Alias Name

Email

Registered Events list

Logout button

CLUB ORGANIZER FLOW

After login → Club Dashboard

Bottom Navigation:

Dashboard

Create Event

Manage Events

Profile

Dashboard Screen

Total events created (mock data)

Total registrations (mock data)

Upcoming events list

Create Event Screen

Form Fields:

Event Title

Description

Date Picker

Time Picker

Venue

Category dropdown

Upload Poster placeholder

Submit button

Use proper form validation.

Manage Events Screen

List of created events

Edit button

Delete button

View discussion button

Club Profile Screen

Club name

Description

Events created count

Logout button

TECH STACK

Framework: Flutter (latest stable)

Language: Dart (null safety enabled)

State Management: Riverpod

Routing: GoRouter

UI System: Material 3

Architecture: Feature-first modular structure

Responsive layout support

Dark mode support

STATE MANAGEMENT REQUIREMENTS

Use Riverpod

Separate providers per feature

Use StateNotifier / Notifier pattern

Keep UI and logic separated

Prepare architecture for Supabase session handling later

BACKEND VISION (FOR PHASE 2)

Although backend is not implemented now, structure must assume future integration with:

Supabase Auth

Supabase PostgreSQL Database

Supabase Realtime

Supabase Storage

Design architecture so that:

Mock repositories can be replaced with Supabase repositories

API layer can be inserted without refactoring UI

Authentication state can later use Supabase session

Realtime features can plug into discussion system

DO NOT INCLUDE

No backend logic

No Supabase integration yet

No Admin Panel

No real authentication logic

No real database connection

FINAL OUTPUT REQUIREMENTS

The generated project must:

Be scalable

Use Riverpod properly

Use GoRouter

Have complete working UI

Have working navigation

Be backend-ready

Be ready for Supabase integration in next phase