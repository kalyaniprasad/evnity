import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Pre-auth
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/auth_screen.dart';

// Student shell + screens
import '../../features/student/shell/student_shell.dart';
import '../../features/student/home/screens/home_screen.dart';
import '../../features/student/calendar/screens/calendar_screen.dart';
import '../../features/student/calendar/screens/day_events_screen.dart';
import '../../features/student/search/screens/search_screen.dart';
import '../../features/student/notifications/screens/notifications_screen.dart';
import '../../features/student/profile/screens/profile_screen.dart';
import '../../features/student/profile/screens/student_profile_edit_screen.dart';
import '../../features/student/event_detail/screens/event_detail_screen.dart';
import '../../features/student/discussion/screens/discussion_screen.dart';
import '../../features/student/event_registration/screens/event_registration_screen.dart';
import '../../features/student/search/screens/student_club_detail_screen.dart';

// Club shell + screens
import '../../features/club/shell/club_shell.dart';
import '../../features/club/dashboard/screens/club_dashboard_screen.dart';
import '../../features/club/create_event/screens/create_event_screen.dart';
import '../../features/club/manage_events/screens/manage_events_screen.dart';
import '../../features/club/profile/screens/club_profile_screen.dart';
import '../../features/club/profile/screens/club_profile_edit_screen.dart';
import '../../features/club/event_detail/screens/club_event_detail_screen.dart';
import '../../features/club/event_edit/screens/event_edit_screen.dart';
import '../../features/club/discussion/screens/club_discussion_screen.dart';
import '../../features/club/dashboard/screens/announcement_screen.dart';
import '../../features/club/dashboard/screens/sent_announcements_screen.dart';

import '../providers/auth_provider.dart';

// ── Auth Guard ────────────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  // Keep the router alive for the lifetime of the app so that the
  // RouterNotifier subscriptions are never torn down mid-session.
  ref.keepAlive();

  // RouterNotifier is a ChangeNotifier that pings GoRouter whenever
  // Firebase auth state or user role changes (see auth_provider.dart).
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final userAsync = ref.read(firebaseUserProvider);
      final roleAsync = ref.read(userRoleProvider);

      // While loading, don't redirect
      if (userAsync.isLoading || roleAsync.isLoading) return null;

      final user = userAsync.valueOrNull;
      final currentPath = state.uri.path;

      // ── Exact match for the three pre-auth screens ─────────────────────
      // BUG-FIX: do NOT use startsWith('/') — every path starts with '/'!
      final isPublic = currentPath == '/' ||
          currentPath == '/onboarding' ||
          currentPath == '/auth';

      // ── Unauthenticated ───────────────────────────────────────────────
      if (user == null) {
        return isPublic ? null : '/auth';
      }

      // ── Authenticated – resolve role ──────────────────────────────────
      final role = roleAsync.valueOrNull;

      // If role is unknown (Firestore error / still resolving) and the user
      // is already inside the app, allow the navigation rather than looping.
      if (role == null) {
        // Kick off the public screens toward a safe default
        return isPublic ? '/home' : null;
      }

      // Push authenticated users away from pre-auth screens
      if (isPublic) {
        return role == 'club' ? '/club/home' : '/home';
      }

      // Keep student/club on their own side of the app
      if (role == 'club' && currentPath == '/home') return '/club/home';
      if (role == 'student' && currentPath == '/club/home') return '/home';

      return null;
    },

    routes: [

      // ── Pre-auth ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (ctx, state) =>
            _fadePage(state.pageKey, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (ctx, state) =>
            _fadePage(state.pageKey, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (ctx, state) =>
            _fadePage(state.pageKey, const AuthScreen()),
      ),

      // ── Student: profile edit (outside shell, full-screen slide) ───────────
      GoRoute(
        path: '/student/profile/edit',
        name: 'studentProfileEdit',
        pageBuilder: (ctx, state) =>
            _slidePage(state.pageKey, const StudentProfileEditScreen()),
      ),

      // ── Student: club detail read-only view (from search) ───────────────
      GoRoute(
        path: '/student/club/:id',
        name: 'studentClubDetail',
        pageBuilder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return _slidePage(
              state.pageKey, StudentClubDetailScreen(clubId: id));
        },
      ),

      // ── Student: event detail + discussion (outside shell) ───────────────
      GoRoute(
        path: '/event/:id',
        name: 'eventDetail',
        pageBuilder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return _slidePage(state.pageKey, EventDetailScreen(eventId: id));
        },
        routes: [
          GoRoute(
            path: 'discussion',
            name: 'discussion',
            pageBuilder: (ctx, state) {
              final id = state.pathParameters['id']!;
              return _slidePage(
                  state.pageKey, DiscussionScreen(eventId: id));
            },
          ),
          GoRoute(
            path: 'register',
            name: 'eventRegister',
            pageBuilder: (ctx, state) {
              final id = state.pathParameters['id']!;
              return _slidePage(
                  state.pageKey, EventRegistrationScreen(eventId: id));
            },
          ),
        ],
      ),

      // ── Student Shell (5 tabs) ────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, shell) =>
            StudentShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              name: 'studentHome',
              pageBuilder: (ctx, state) =>
                  _noTransitionPage(state.pageKey, const HomeScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calendar',
              name: 'studentCalendar',
              pageBuilder: (ctx, state) =>
                  _noTransitionPage(state.pageKey, const CalendarScreen()),
              routes: [
                GoRoute(
                  path: 'day-events',
                  name: 'studentDayEvents',
                  pageBuilder: (ctx, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    final date = extra?['date'] as DateTime? ?? DateTime.now();
                    final events = extra?['events'] as List<dynamic>? ?? [];
                    return _slidePage(
                      state.pageKey,
                      DayEventsScreen(date: date, events: events.cast()),
                    );
                  },
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/search',
              name: 'studentSearch',
              pageBuilder: (ctx, state) =>
                  _noTransitionPage(state.pageKey, const SearchScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/notifications',
              name: 'studentNotifications',
              pageBuilder: (ctx, state) =>
                  _noTransitionPage(
                      state.pageKey, const NotificationsScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              name: 'studentProfile',
              pageBuilder: (ctx, state) =>
                  _noTransitionPage(state.pageKey, const ProfileScreen()),
            ),
          ]),
        ],
      ),

      // ── Club: event detail + discussion (outside shell) ──────────────────
      GoRoute(
        path: '/club/event/:id',
        name: 'clubEventDetail',
        pageBuilder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return _slidePage(
              state.pageKey, ClubEventDetailScreen(eventId: id));
        },
        routes: [
          GoRoute(
            path: 'discussion',
            name: 'clubDiscussion',
            pageBuilder: (ctx, state) {
              final id = state.pathParameters['id']!;
              return _slidePage(
                  state.pageKey, ClubDiscussionScreen(eventId: id));
            },
          ),
          GoRoute(
            path: 'announcement',
            name: 'clubEventAnnouncement',
            pageBuilder: (ctx, state) {
              final id = state.pathParameters['id']!;
              return _slidePage(
                  state.pageKey, AnnouncementScreen(eventId: id));
            },
          ),
        ],
      ),
      GoRoute(
        path: '/club/event/:id/edit',
        name: 'clubEventEdit',
        pageBuilder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return _slidePage(state.pageKey, EventEditScreen(eventId: id));
        },
      ),

      // ── Club: profile edit (outside shell, full-screen slide) ────────────
      GoRoute(
        path: '/club/profile/edit',
        name: 'clubProfileEdit',
        pageBuilder: (ctx, state) =>
            _slidePage(state.pageKey, const ClubProfileEditScreen()),
      ),
      GoRoute(
        path: '/club/announcement',
        name: 'clubAnnouncement',
        pageBuilder: (ctx, state) =>
            _slidePage(state.pageKey, const AnnouncementScreen()),
      ),
      GoRoute(
        path: '/club/announcements/history',
        name: 'clubAnnouncementHistory',
        pageBuilder: (ctx, state) =>
            _slidePage(state.pageKey, const SentAnnouncementsScreen()),
      ),

      // ── Club Shell (4 tabs) ───────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, shell) =>
            ClubShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/club/home',
              name: 'clubHome',
              pageBuilder: (ctx, state) =>
                  _noTransitionPage(
                      state.pageKey, const ClubDashboardScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/club/create',
              name: 'clubCreate',
              pageBuilder: (ctx, state) =>
                  _noTransitionPage(
                      state.pageKey, const CreateEventScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/club/manage',
              name: 'clubManage',
              pageBuilder: (ctx, state) =>
                  _noTransitionPage(
                      state.pageKey, const ManageEventsScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/club/profile',
              name: 'clubProfile',
              pageBuilder: (ctx, state) =>
                  _noTransitionPage(
                      state.pageKey, const ClubProfileScreen()),
            ),
          ]),
        ],
      ),
    ],
  );
});

// ── Page Transitions ──────────────────────────────────────────────────────────

CustomTransitionPage _fadePage(LocalKey key, Widget child) =>
    CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 380),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );

CustomTransitionPage _slidePage(LocalKey key, Widget child) =>
    CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (_, anim, _, child) => SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(1.0, 0), end: Offset.zero)
            .animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

NoTransitionPage _noTransitionPage(LocalKey key, Widget child) =>
    NoTransitionPage(key: key, child: child);
