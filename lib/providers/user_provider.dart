import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider extends ChangeNotifier {
  bool _isAdmin = false;
  bool _isLoading = true;
  User? _user;

  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  User? get user => _user;

  UserProvider() {
    _init();
  }

  void _init() {
    _user = Supabase.instance.client.auth.currentUser;
    _listenToAuthChanges();
    fetchUserRole();
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      final User? newUser = session?.user;

      if (_user?.id != newUser?.id) {
        _user = newUser;
        if (_user != null) {
          fetchUserRole();
        } else {
          _isAdmin = false;
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  Future<void> fetchUserRole() async {
    final currentUser = _user;
    if (currentUser == null) {
      _isAdmin = false;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      // notifyListeners(); // Avoid notifying here to prevent unnecessary rebuilds if called frequently, but useful for loading states

      final userId = currentUser.id;
      bool foundAdmin = false;

      // 1. Check admins table
      try {
        debugPrint('UserProvider: Checking admins table for id: $userId');
        final adminRow = await Supabase.instance.client
            .from('admins')
            .select()
            .eq('id', userId) // Reverted to 'id'
            .maybeSingle();

        debugPrint('UserProvider: admins table result: $adminRow');
        if (adminRow != null) {
          foundAdmin = true;
        }
      } catch (e) {
        debugPrint('UserProvider: Error checking admins table: $e');
      }

      // 2. Check users table if not already found
      if (!foundAdmin) {
        try {
          debugPrint('UserProvider: Checking users table (id) for id: $userId');
          final userRow = await Supabase.instance.client
              .from('users')
              .select('is_admin')
              .eq('id', userId)
              .maybeSingle();

          debugPrint('UserProvider: users table (id) result: $userRow');

          if (userRow != null && userRow['is_admin'] == true) {
            foundAdmin = true;
          }
        } catch (e) {
          debugPrint('UserProvider: Error checking users table (id): $e');
        }
      }

      // 3. Check users table (using 'uid' - legacy support)
      if (!foundAdmin) {
        try {
          debugPrint(
              'UserProvider: Checking users table (uid) for uid: $userId');
          final userRowUid = await Supabase.instance.client
              .from('users')
              .select('is_admin')
              .eq('uid', userId)
              .maybeSingle();

          debugPrint('UserProvider: users table (uid) result: $userRowUid');

          if (userRowUid != null && userRowUid['is_admin'] == true) {
            foundAdmin = true;
          }
        } catch (e) {
          debugPrint('UserProvider: Error checking users table (uid): $e');
        }
      }

      _isAdmin = foundAdmin;
      debugPrint('UserProvider: Final Admin Status: $_isAdmin');
    } catch (e) {
      debugPrint('UserProvider: Global error checking role: $e');
      _isAdmin = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
