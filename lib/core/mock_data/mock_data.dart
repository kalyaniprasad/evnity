import '../models/models.dart';

// ── Mock Events ───────────────────────────────────────────────────────────────
final List<EventModel> kMockEvents = [
  const EventModel(
    id: 'e1',
    title: 'TechFest 2025 — National Hackathon',
    hostClubId: 'c1',
    clubName: 'CodeCraft Club',
    organizerName: 'CodeCraft Club',
    clubLogoUrl: '',
    date: 'Sat, 15 Mar 2026',
    time: '9:00 AM',
    venue: 'Main Auditorium, Block A',
    category: 'Technical',
    posterUrl:
        'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&q=80',
    description:
        'Join us for the biggest hackathon of the year! 24 hours of coding, innovation, and prizes worth ₹1,00,000. Open to all students across departments. Form teams of 2–4 and build solutions for real-world problems. Mentors from top tech companies will be present.',
    registrationCount: 142,
    isRegistered: false,
  ),
  const EventModel(
    id: 'e2',
    title: 'Culturals Night — Echoes of India',
    hostClubId: 'c2',
    clubName: 'Rangmanch Cultural Club',
    organizerName: 'Rangmanch Cultural Club',
    clubLogoUrl: '',
    date: 'Sat, 21 Mar 2026',
    time: '6:00 PM',
    venue: 'Open Air Theatre',
    category: 'Cultural',
    posterUrl:
        'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800&q=80',
    description:
        'A spectacular evening of dance, music, and drama celebrating the rich cultural heritage of India. Featuring performances by student groups from across the campus. Special guest performances and exciting prizes for participants.',
    registrationCount: 87,
    isRegistered: true,
  ),
  const EventModel(
    id: 'e3',
    title: 'Inter-College Basketball Tournament',
    hostClubId: 'c3',
    clubName: 'Sports Council',
    organizerName: 'Sports Council',
    clubLogoUrl: '',
    date: 'Mon, 23 Mar 2026',
    time: '8:00 AM',
    venue: 'Sports Complex, Ground Floor',
    category: 'Sports',
    posterUrl:
        'https://images.unsplash.com/photo-1546519638405-a9f9f7afeba2?w=800&q=80',
    description:
        'The annual inter-college basketball tournament is back! Teams from 12 colleges will compete for the champion trophy. Come support your team or register to participate.',
    registrationCount: 64,
    isRegistered: false,
  ),
  const EventModel(
    id: 'e4',
    title: 'UI/UX Design Workshop',
    hostClubId: 'c4',
    clubName: 'Design Collective',
    organizerName: 'Design Collective',
    clubLogoUrl: '',
    date: 'Thu, 26 Mar 2026',
    time: '2:00 PM',
    venue: 'Computer Lab 3, Block C',
    category: 'Workshop',
    posterUrl:
        'https://images.unsplash.com/photo-1558655146-9f40138edfeb?w=800&q=80',
    description:
        'A hands-on workshop on modern UI/UX design principles using Figma. Learn prototyping, wireframing, and user research from industry experts. Certificate of participation provided.',
    registrationCount: 55,
    isRegistered: false,
  ),
  const EventModel(
    id: 'e5',
    title: 'Entrepreneurship Summit 2025',
    hostClubId: 'c5',
    clubName: 'E-Cell',
    organizerName: 'E-Cell',
    clubLogoUrl: '',
    date: 'Fri, 3 Apr 2026',
    time: '10:00 AM',
    venue: 'Seminar Hall, Block B',
    category: 'Seminar',
    posterUrl:
        'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=800&q=80',
    description:
        'Connect with successful entrepreneurs, investors, and startup founders. Panel discussions, pitch competitions, and networking sessions. Exclusive mentorship slots available for interested students.',
    registrationCount: 210,
    isRegistered: false,
  ),
  const EventModel(
    id: 'e6',
    title: 'Photography Walk — Monsoon Edition',
    hostClubId: 'c6',
    clubName: 'Shutter Club',
    organizerName: 'Shutter Club',
    clubLogoUrl: '',
    date: 'Sun, 5 Apr 2026',
    time: '7:00 AM',
    venue: 'Campus Garden, Main Gate',
    category: 'Cultural',
    posterUrl:
        'https://images.unsplash.com/photo-1452587925148-ce544e77e70d?w=800&q=80',
    description:
        'Grab your camera and join us for a guided photography walk through the scenic campus garden. All skill levels welcome. Best photographs will be featured in the college magazine.',
    registrationCount: 33,
    isRegistered: false,
  ),
];

// ── Mock User ─────────────────────────────────────────────────────────────────
const kMockUser = UserModel(
  id: 'u1',
  email: 'student@college.edu',
  aliasName: 'EventExplorer45',
  role: 'student',
  registeredEventIds: ['e2'],
);

// ── Mock Notifications ────────────────────────────────────────────────────────
final List<NotificationModel> kMockNotifications = [
  const NotificationModel(
    id: 'n1',
    title: 'Registration Confirmed! 🎉',
    description: 'You are registered for Culturals Night — Echoes of India.',
    timestamp: '2 min ago',
    type: NotificationType.registration,
    isRead: false,
    eventId: 'e2',
  ),
  const NotificationModel(
    id: 'n2',
    title: 'TechFest Venue Update',
    description: 'Venue changed to Main Auditorium, Block A. Please note.',
    timestamp: '1 hour ago',
    type: NotificationType.eventUpdate,
    isRead: false,
    eventId: 'e1',
  ),
  const NotificationModel(
    id: 'n3',
    title: 'Reminder: Basketball Tomorrow',
    description: 'Inter-College Basketball starts at 8:00 AM tomorrow.',
    timestamp: '3 hours ago',
    type: NotificationType.reminder,
    isRead: true,
    eventId: 'e3',
  ),
  const NotificationModel(
    id: 'n4',
    title: 'College Announcement 📢',
    description: 'All events in Block B are rescheduled due to maintenance.',
    timestamp: 'Yesterday',
    type: NotificationType.announcement,
    isRead: true,
  ),
  const NotificationModel(
    id: 'n5',
    title: 'New Event: Photography Walk',
    description: 'Shutter Club posted a new event. Check it out!',
    timestamp: 'Yesterday',
    type: NotificationType.eventUpdate,
    isRead: true,
    eventId: 'e6',
  ),
  const NotificationModel(
    id: 'n6',
    title: 'Workshop Seats Filling Fast!',
    description: 'Only 5 seats left for the UI/UX Design Workshop.',
    timestamp: '2 days ago',
    type: NotificationType.reminder,
    isRead: true,
    eventId: 'e4',
  ),
];

// ── Mock Messages ─────────────────────────────────────────────────────────────
final List<MessageModel> kMockMessages = [
  const MessageModel(
    id: 'm1',
    senderId: 'u1',
    senderAlias: 'EventExplorer45',
    message: 'Hey! Is this open for first year students?',
    timestamp: '10:30 AM',
    senderType: MessageSenderType.student,
  ),
  const MessageModel(
    id: 'm2',
    senderId: 'org1',
    senderAlias: 'CodeCraft Organizer',
    message:
        'Yes absolutely! All students are welcome regardless of year. Just bring your student ID.',
    timestamp: '10:32 AM',
    senderType: MessageSenderType.organizer,
  ),
  const MessageModel(
    id: 'm3',
    senderId: 'u2',
    senderAlias: 'TechNova99',
    message: 'What is the maximum team size?',
    timestamp: '10:45 AM',
    senderType: MessageSenderType.student,
  ),
  const MessageModel(
    id: 'm4',
    senderId: 'org1',
    senderAlias: 'CodeCraft Organizer',
    message: 'Teams can be 2 to 4 members. Solo participation is not allowed.',
    timestamp: '10:47 AM',
    senderType: MessageSenderType.organizer,
  ),
  const MessageModel(
    id: 'm5',
    senderId: 'u3',
    senderAlias: 'ByteWizard22',
    message: 'Will food be provided during the 24 hour hackathon?',
    timestamp: '11:00 AM',
    senderType: MessageSenderType.student,
  ),
  const MessageModel(
    id: 'm6',
    senderId: 'org1',
    senderAlias: 'CodeCraft Organizer',
    message:
        'Yes! Meals, snacks, and refreshments will be provided throughout the event. ☕🍕',
    timestamp: '11:02 AM',
    senderType: MessageSenderType.organizer,
  ),
  const MessageModel(
    id: 'm7',
    senderId: 'u1',
    senderAlias: 'EventExplorer45',
    message: 'Amazing! Can we use any tech stack for the project?',
    timestamp: '11:10 AM',
    senderType: MessageSenderType.student,
  ),
  const MessageModel(
    id: 'm8',
    senderId: 'org1',
    senderAlias: 'CodeCraft Organizer',
    message:
        'Completely open stack! Web, mobile, AI, IoT — anything works as long as it solves the problem statement.',
    timestamp: '11:12 AM',
    senderType: MessageSenderType.organizer,
  ),
];

// ── Mock Clubs ────────────────────────────────────────────────────────────────
final List<ClubModel> kMockClubs = [
  const ClubModel(
    id: 'c1',
    name: 'CodeCraft Club',
    description:
        'CodeCraft Club is the premier technical club on campus. We organize hackathons, workshops, and seminars to build the next generation of developers. We believe in learning by doing and creating impact through code.',
    category: 'Technical',
    logoUrl: '',
    memberCount: 320,
    eventCount: 12,
    facultyMentor: 'Dr. Rajesh Sharma',
    totalRegistrations: 1420,
  ),
  const ClubModel(
    id: 'c2',
    name: 'Rangmanch Cultural Club',
    description:
        'Rangmanch is where art, music, dance, and drama come alive. From intimate classical performances to high-energy fusion shows, we celebrate every art form. Open to all students who share a passion for cultural expression.',
    category: 'Cultural',
    logoUrl: '',
    memberCount: 185,
    eventCount: 8,
    facultyMentor: 'Prof. Anita Verma',
    totalRegistrations: 740,
  ),
  const ClubModel(
    id: 'c3',
    name: 'Sports Council',
    description:
        'The Sports Council coordinates all intra and inter-college sports activities. From cricket to badminton, athletics to chess — we promote fitness, teamwork, and competitive spirit across the campus.',
    category: 'Sports',
    logoUrl: '',
    memberCount: 410,
    eventCount: 20,
    facultyMentor: 'Dr. Suresh Nair',
    totalRegistrations: 2100,
  ),
  const ClubModel(
    id: 'c4',
    name: 'Design Collective',
    description:
        'Design Collective runs hands-on workshops in UI/UX, graphic design, motion graphics, and brand identity. We bridge the gap between creativity and technology, preparing students for design careers in the real world.',
    category: 'Workshop',
    logoUrl: '',
    memberCount: 98,
    eventCount: 6,
    facultyMentor: 'Ms. Priya Menon',
    totalRegistrations: 380,
  ),
  const ClubModel(
    id: 'c5',
    name: 'E-Cell',
    description:
        'The Entrepreneurship Cell fosters innovation and startup culture on campus. Through speaker sessions, pitch competitions, and incubator programs, we help students transform ideas into impactful ventures.',
    category: 'Seminar',
    logoUrl: '',
    memberCount: 260,
    eventCount: 9,
    facultyMentor: 'Prof. Amit Kulkarni',
    totalRegistrations: 1150,
  ),
  const ClubModel(
    id: 'c6',
    name: 'Shutter Club',
    description:
        'Shutter Club is for photography and film enthusiasts. We host photo walks, editing workshops, and short film screenings. All skill levels are welcome — from smartphone shooters to DSLR pros.',
    category: 'Cultural',
    logoUrl: '',
    memberCount: 112,
    eventCount: 7,
    facultyMentor: 'Dr. Meera Pillai',
    totalRegistrations: 310,
  ),
];

// ── Category List ─────────────────────────────────────────────────────────────
const List<String> kCategories = [
  'All',
  'Technical',
  'Cultural',
  'Sports',
  'Workshop',
  'Seminar',
];
