class HomeRepository {
  Future<Map<String, dynamic>> fetchHomeData() async {
    // Simula una llamada a red
    await Future.delayed(const Duration(seconds: 1));
    return {
      'userName': 'Alex',
      'xpProgress': 1250,
      'xpTotal': 2000,
      'pendingTasks': [
        {'title': 'Submit Physics Lab Report', 'priority': 'HIGH'},
        {'title': 'Read Chapter 4: Calculus', 'priority': 'MED'},
      ]
    };
  }
}