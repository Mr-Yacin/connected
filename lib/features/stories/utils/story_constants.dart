/// Constants for the stories feature
/// 
/// Centralizes magic numbers, durations, sizes, and other constant values
/// used throughout the stories feature for consistency and maintainability.
class StoryConstants {
  // Private constructor to prevent instantiation
  StoryConstants._();

  // ============================================================================
  // DURATIONS
  // ============================================================================
  
  /// Duration for each story display (5 seconds)
  static const Duration storyDuration = Duration(seconds: 5);
  
  /// Duration for story expiration (24 hours)
  static const Duration storyExpirationDuration = Duration(hours: 24);
  
  /// Animation duration for page transitions
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);

  // ============================================================================
  // SIZES
  // ============================================================================
  
  /// Standard profile avatar size
  static const double profileAvatarSize = 40.0;
  
  /// Profile avatar border width
  static const double profileAvatarBorder = 2.0;
  
  /// Story progress indicator height
  static const double storyProgressHeight = 3.0;
  
  /// Story stats icon size
  static const double statsIconSize = 14.0;
  
  /// Story stats font size
  static const double statsFontSize = 11.0;
  
  /// Quick reaction emoji size
  static const double quickReactionSize = 36.0;
  
  /// Send button size
  static const double sendButtonSize = 44.0;
  
  /// Like button size
  static const double likeButtonSize = 44.0;

  // ============================================================================
  // GRID LAYOUT
  // ============================================================================
  
  /// Number of columns in stories grid
  static const int gridCrossAxisCount = 3;
  
  /// Aspect ratio for story cards in grid
  static const double gridAspectRatio = 0.7;
  
  /// Spacing between grid items
  static const double gridSpacing = 8.0;
  
  /// Padding around grid
  static const double gridPadding = 16.0;

  // ============================================================================
  // SPACING
  // ============================================================================
  
  /// Standard spacing between stats items
  static const double statsSpacing = 12.0;
  
  /// Spacing between quick reaction rows
  static const double quickReactionRowSpacing = 12.0;
  
  /// Padding for bottom action bars
  static const double bottomActionPadding = 12.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  
  /// Border radius for story cards
  static const double cardBorderRadius = 12.0;
  
  /// Border radius for bottom sheets
  static const double bottomSheetBorderRadius = 20.0;
  
  /// Border radius for input fields
  static const double inputBorderRadius = 30.0;
  
  /// Border radius for buttons
  static const double buttonBorderRadius = 12.0;
  
  /// Border radius for circular buttons
  static const double circularButtonRadius = 24.0;

  // ============================================================================
  // OPACITY VALUES
  // ============================================================================
  
  /// Overlay opacity for gradients
  static const double overlayOpacity = 0.7;
  
  /// Light overlay opacity
  static const double lightOverlayOpacity = 0.3;
  
  /// Input background opacity
  static const double inputBackgroundOpacity = 0.2;
  
  /// Border opacity
  static const double borderOpacity = 0.3;

  // ============================================================================
  // BLUR VALUES
  // ============================================================================
  
  /// Blur sigma for backdrop filters
  static const double backdropBlurSigma = 10.0;
  
  /// Shadow blur radius
  static const double shadowBlurRadius = 4.0;

  // ============================================================================
  // QUICK REACTIONS
  // ============================================================================
  
  /// Default quick reaction emojis (first row)
  static const List<String> quickReactionsRow1 = ['😂', '😮', '😍', '😢'];
  
  /// Default quick reaction emojis (second row)
  static const List<String> quickReactionsRow2 = ['👏', '🔥', '🎉', '💯'];
  
  /// All quick reaction emojis
  static const List<String> allQuickReactions = [
    ...quickReactionsRow1,
    ...quickReactionsRow2,
  ];

  // ============================================================================
  // SCROLL BEHAVIOR
  // ============================================================================
  
  /// Scroll threshold for triggering shuffle (95% of max scroll)
  static const double scrollShuffleThreshold = 0.95;
  
  /// Number of stories before always shuffling
  static const int minStoriesForConditionalShuffle = 10;
  
  /// Shuffle every N scrolls when many stories
  static const int shuffleEveryNScrolls = 3;

  // ============================================================================
  // TEXT
  // ============================================================================
  
  /// Placeholder text for message input
  static const String messageInputPlaceholder = 'أرسل رسالة...';
  
  /// Text for "now" time ago
  static const String timeAgoNow = 'الآن';
  
  /// Success message for story deletion
  static const String storyDeletedSuccess = 'تم حذف القصة بنجاح';
  
  /// Success message for message sent
  static const String messageSentSuccess = 'تم إرسال الرسالة';
  
  /// Error message for like update failure
  static const String likeUpdateError = 'فشل في تحديث الإعجاب';
}
