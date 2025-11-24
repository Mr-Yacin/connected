class AppConstants {
  // App Info
  static const String appName = 'تطبيق التواصل الاجتماعي';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String storiesCollection = 'stories';
  static const String reportsCollection = 'reports';
  static const String blocksCollection = 'blocks';
  
  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String voiceMessagesPath = 'voice_messages';
  static const String storiesPath = 'stories';
  
  // Auth
  static const int otpResendCooldown = 60; // seconds
  static const int maxOtpAttempts = 3;
  static const int rateLimitDuration = 5; // minutes
  
  // Stories
  static const int storyDuration = 24; // hours
  
  // File Limits
  static const int maxProfileImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVoiceMessageSize = 10 * 1024 * 1024; // 10MB
  static const int maxStorySize = 20 * 1024 * 1024; // 20MB
  
  // Pagination
  static const int messagesPageSize = 50;
  static const int storiesPageSize = 20;
}
