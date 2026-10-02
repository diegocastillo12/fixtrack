import 'package:supabase_flutter/supabase_flutter.dart';

/// Helpers de acceso rápido a Supabase
extension SupaExt on SupabaseClient {
  String? get userId => auth.currentUser?.id;
}
