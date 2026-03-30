import 'package:flutter/material.dart';

import '../repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository();
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  ProfileViewModel() {
    loadProfile();
  }

  Future<void> loadProfile() async {
    profileData = await _repository.fetchProfile();
    isLoading = false;
    notifyListeners();
  }
}