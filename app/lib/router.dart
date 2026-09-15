import 'package:go_router/go_router.dart';

import 'screens/admin_dashboard.dart';
import 'screens/content_viewer_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/quiz_list_screen.dart';
import 'screens/quiz_play_screen.dart';
import 'screens/quiz_result_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/subject_screen.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/teacher_quiz_create_screen.dart';
import 'screens/teacher_quiz_results_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/otp', builder: (context, state) => OtpScreen(args: state.extra as OtpArgs)),
    GoRoute(path: '/student', builder: (context, state) => const StudentDashboard()),
    GoRoute(
      path: '/student/subject/:id',
      builder: (context, state) => SubjectScreen(
        subjectId: int.parse(state.pathParameters['id']!),
        subjectName: state.extra as String? ?? 'Subject',
      ),
    ),
    GoRoute(
      path: '/student/content',
      builder: (context, state) => ContentViewerScreen(content: state.extra as Map<String, dynamic>),
    ),
    GoRoute(
      path: '/student/quizzes/:id',
      builder: (context, state) => QuizListScreen(
        subjectId: int.parse(state.pathParameters['id']!),
        subjectName: state.extra as String? ?? 'Subject',
      ),
    ),
    GoRoute(
      path: '/student/quiz/:id',
      builder: (context, state) => QuizPlayScreen(
        quizId: int.parse(state.pathParameters['id']!),
        quizTitle: state.extra as String? ?? 'Quiz',
      ),
    ),
    GoRoute(
      path: '/student/quiz-result',
      builder: (context, state) => QuizResultScreen(result: state.extra as Map<String, dynamic>),
    ),
    GoRoute(path: '/teacher', builder: (context, state) => const TeacherDashboard()),
    GoRoute(
      path: '/teacher/quiz-create',
      builder: (context, state) => TeacherQuizCreateScreen(subjects: state.extra as List<dynamic>),
    ),
    GoRoute(
      path: '/teacher/quiz-results/:id',
      builder: (context, state) => TeacherQuizResultsScreen(
        quizId: int.parse(state.pathParameters['id']!),
        quizTitle: state.extra as String? ?? 'Quiz',
      ),
    ),
    GoRoute(path: '/admin', builder: (context, state) => const AdminDashboard()),
  ],
);
