class AppRoutes {
  static const root = '/';
  static const home = '/home';
  static const training = '/training';
  static const workout = '/training/workout/:id';
  static const progress = '/progress';
  static const health = '/health';
  static const healthLab = '/health/labs/:id';
  static const nutrition = '/nutrition';
  static const more = '/more';
  static const careTeam = '/care-team';
  static const competition = '/competition';
  static const profile = '/profile';
  static const settings = '/settings';
  static const records = '/records';
  static const messages = '/messages';

  static String workoutPath(String workoutId) => '/training/workout/$workoutId';
}
