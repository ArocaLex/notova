import 'package:flutter/material.dart';

import '../repositories/home_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeRepository _repository = HomeRepository();
  
  bool isLoading = true;
  Map<String, dynamic> data = {};

  HomeViewModel() {
    loadData();
  }

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();
    
    data = await _repository.fetchHomeData();
    
    isLoading = false;
    notifyListeners();
  }
}