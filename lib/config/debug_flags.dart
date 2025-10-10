// Simple debug flags for development builds.
// IMPORTANT: These flags only apply in debug mode (kDebugMode).

class AppDebugFlags {
  // When true in debug builds, allows starting DMs even if trust gating
  // would normally restrict (still respects user blocks and safety filters).
  static const bool allowDMOverride = true;
}
