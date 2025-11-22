import 'dart:async';

import 'package:eisen/features/settings/data/language_prefs_repository.dart';
import 'package:eisen/features/settings/domain/language_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageController extends AsyncNotifier<LanguagePrefs> {
  late final LanguagePrefsRepository _repo;

  @override
  FutureOr<LanguagePrefs> build() async {
    _repo = ref.read(languagePrefsRepositoryProvider);
    final prefs = await _repo.load();
    return prefs;
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = LanguagePrefs(locale);
    state = AsyncData(prefs);
    await _repo.save(prefs);
  }
}

final languageControllerProvider =
    AsyncNotifierProvider<LanguageController, LanguagePrefs>(
        LanguageController.new);
