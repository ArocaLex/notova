class ProfileRepository {
  Future<Map<String, dynamic>> fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'name': 'Alex Rivers',
      'rank': 'Master Student',
      'level': 42,
      'currentXp': 750,
      'totalXp': 12450,
      'dayStreak': 15,
      'badgesCount': 28,
    };
  }
}