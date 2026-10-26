import 'package:flutter/foundation.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/features/profile/domain/entities/profile.dart';
import 'package:bookslane_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._repository);

  final ProfileRepository _repository;

  Profile? _profile;
  String? _error;
  bool _isLoading = false;

  Profile? get profile => _profile;
  String? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _repository.fetchProfile();
    } on ApiFailure catch (failure) {
      _error = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
