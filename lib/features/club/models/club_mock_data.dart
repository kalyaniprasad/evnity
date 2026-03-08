import 'club_event.dart';
import 'club_message.dart';

const List<String> kClubEventCategories = [
  'Technical',
  'Cultural',
  'Sports',
  'Workshop',
  'Seminar',
];

final List<ClubEvent> kMockClubEvents = [
  const ClubEvent(
    id: 'ce1',
    title: 'TechFest 2025 — National Hackathon',
    category: 'Technical',
    date: 'Sat, 15 Mar 2025',
    time: '9:00 AM',
    venue: 'Main Auditorium, Block A',
    posterUrl:
        'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&q=80',
    description:
        'Join us for the biggest hackathon of the year! 24 hours of coding, innovation, and prizes worth ₹1,00,000. Open to all students. Teams of 2–4. Mentors from top tech companies will guide you.',
    status: EventStatus.published,
    registrationCount: 142,
    messageCount: 24,
  ),
  const ClubEvent(
    id: 'ce2',
    title: 'Flutter Workshop — Build Your First App',
    category: 'Workshop',
    date: 'Wed, 19 Mar 2025',
    time: '2:00 PM',
    venue: 'Computer Lab 3, Block C',
    posterUrl:
        'https://images.unsplash.com/photo-1558655146-9f40138edfeb?w=800&q=80',
    description:
        'A beginner-friendly hands-on Flutter workshop. Learn to build cross-platform apps in one session. Certificate of participation provided.',
    status: EventStatus.published,
    registrationCount: 58,
    messageCount: 9,
  ),
  const ClubEvent(
    id: 'ce3',
    title: 'AI & ML Seminar — Future of Tech',
    category: 'Seminar',
    date: 'Fri, 28 Mar 2025',
    time: '11:00 AM',
    venue: 'Seminar Hall, Block B',
    posterUrl:
        'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=800&q=80',
    description:
        'Deep dive into AI and Machine Learning with industry experts. Panel discussions, live demos and Q&A sessions included.',
    status: EventStatus.draft,
    registrationCount: 0,
    messageCount: 0,
  ),
  const ClubEvent(
    id: 'ce4',
    title: 'Open Source Contribution Day',
    category: 'Technical',
    date: 'Sat, 5 Apr 2025',
    time: '10:00 AM',
    venue: 'Innovation Lab, Block D',
    posterUrl:
        'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800&q=80',
    description:
        'Contribute to open source projects, learn git workflows, and collaborate with fellow developers. All skill levels welcome.',
    status: EventStatus.draft,
    registrationCount: 0,
    messageCount: 2,
  ),
];

final List<ClubMessage> kMockClubMessages = [
  const ClubMessage(
    id: 'cm1',
    senderAlias: 'EventExplorer45',
    message: 'Hey! Is this event open for first year students?',
    timestamp: '10:30 AM',
    senderType: ClubMessageSender.student,
  ),
  const ClubMessage(
    id: 'cm2',
    senderAlias: 'CodeCraft Organizer',
    message:
        'Yes absolutely! All students are welcome regardless of year. Just bring your student ID.',
    timestamp: '10:32 AM',
    senderType: ClubMessageSender.organizer,
  ),
  const ClubMessage(
    id: 'cm3',
    senderAlias: 'TechNova99',
    message: 'What is the maximum team size for the hackathon?',
    timestamp: '10:45 AM',
    senderType: ClubMessageSender.student,
  ),
  const ClubMessage(
    id: 'cm4',
    senderAlias: 'CodeCraft Organizer',
    message: 'Teams can be 2 to 4 members. Solo participation is not allowed.',
    timestamp: '10:47 AM',
    senderType: ClubMessageSender.organizer,
  ),
  const ClubMessage(
    id: 'cm5',
    senderAlias: 'ByteWizard22',
    message: 'Will food be provided during the 24-hour hackathon?',
    timestamp: '11:00 AM',
    senderType: ClubMessageSender.student,
  ),
  const ClubMessage(
    id: 'cm6',
    senderAlias: 'CodeCraft Organizer',
    message:
        'Yes! Meals, snacks and refreshments will be provided throughout. ☕🍕',
    timestamp: '11:02 AM',
    senderType: ClubMessageSender.organizer,
  ),
  const ClubMessage(
    id: 'cm7',
    senderAlias: 'PixelCoder07',
    message: 'Can we use any programming language or framework?',
    timestamp: '11:15 AM',
    senderType: ClubMessageSender.student,
  ),
  const ClubMessage(
    id: 'cm8',
    senderAlias: 'CodeCraft Organizer',
    message:
        'Completely open stack! Web, mobile, AI, IoT — anything that solves the problem.',
    timestamp: '11:17 AM',
    senderType: ClubMessageSender.organizer,
  ),
];
