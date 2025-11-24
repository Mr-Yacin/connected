/// Message types supported in the chat system
enum MessageType {
  text,
  voice,
}

/// Story media types
enum StoryType {
  image,
  video,
}

/// Types of content that can be reported
enum ReportType {
  user,
  message,
  story,
}

/// Status of a moderation report
enum ReportStatus {
  pending,
  reviewed,
  resolved,
}
