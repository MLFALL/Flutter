import 'package:get/get.dart';

// Import all screens
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';

// Auth screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/profile_screen.dart';

// Projects screens
import '../screens/projects/projects_list_screen.dart';
import '../screens/projects/project_details_screen.dart';
import '../screens/projects/create_project_screen.dart';
import '../screens/projects/kanban_board_screen.dart';

// Tasks screens
import '../screens/tasks/tasks_list_screen.dart';
import '../screens/tasks/task_details_screen.dart';
import '../screens/tasks/create_task_screen.dart';

// Admin screens
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/manage_users_screen.dart';

// Files screens
import '../screens/files/file_list_screen.dart';
import '../screens/files/file_viewer_screen.dart';

class AppRoutes {
  // Static route names
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const profile = '/profile';

  static const home = '/home';

  static const projectsList = '/projects';
  static const projectDetails = '/projects/:id';
  static const createProject = '/projects/create/new';
  static const kanbanBoard = '/projects/:id/kanban';

  static const tasksList = '/tasks';
  static const taskDetails = '/tasks/:id';
  static const createTask = '/projects/:projectId/tasks/create';

  static const adminDashboard = '/admin/dashboard';
  static const manageUsers = '/admin/users';

  static const fileList = '/projects/:projectId/files';
  static const fileViewer = '/files/:id/view';

  // Routes list
  static final routes = [
    // Entry and authentication
    GetPage(name: '/splash', page: () => SplashScreen()),
    GetPage(name: '/login', page: () => LoginScreen()),
    GetPage(name: '/register', page: () => RegisterScreen()),
    GetPage(name: '/forgot-password', page: () => ForgotPasswordScreen()),
    GetPage(name: '/profile', page: () => ProfileScreen()),

    // Main navigation
    GetPage(name: '/home', page: () => HomeScreen()),

    // Projects
    GetPage(name: '/projects', page: () => ProjectsListScreen()),
    GetPage(
      name: '/projects/:id',
      page: () => ProjectDetailsScreen(
        projectId: Get.parameters['id']!,
      ),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/projects/create/new',
      page: () => CreateProjectScreen(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: '/projects/:id/kanban',
      page: () => KanbanBoardScreen(),
      transition: Transition.rightToLeft,
    ),

    // Tasks
    GetPage(name: '/tasks', page: () => TasksListScreen()),
    GetPage(
      name: '/tasks/:id',
      page: () => TaskDetailsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/projects/:projectId/tasks/create',
      page: () => CreateTaskScreen(),
      transition: Transition.downToUp,
    ),

    // Admin section
    GetPage(
      name: '/admin/dashboard',
      page: () => AdminDashboardScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.manageUsers,
      page: () => ManageUsersScreen(),
      transition: Transition.rightToLeft,
    ),

    // File management
    GetPage(
      name: '/projects/:projectId/files',
      page: () => FileListScreen(
        projectId: Get.parameters['projectId']!,
      ),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/files/:id/view',
      page: () => FileViewerScreen(),
      transition: Transition.zoom,
    ),
  ];
}