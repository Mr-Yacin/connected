const {onObjectFinalized} = require("firebase-functions/v2/storage");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");
const {spawn} = require("child-process-promise");
const path = require("path");
const os = require("os");
const fs = require("fs");

const storage = admin.storage();

/**
 * Cloud Function: optimizeImage
 * Trigger: Storage onFinalize for uploaded images
 * Purpose: Create optimized versions and thumbnails of uploaded images
 *
 * Process:
 * 1. Download original image
 * 2. Create thumbnail (200x200)
 * 3. Create optimized version (max 1920px width, WebP format)
 * 4. Upload optimized versions
 * 5. Update Firestore with optimized URLs
 */
exports.optimizeImage = onObjectFinalized(
  {
    cpu: 2,
    memory: "2GiB",
    timeoutSeconds: 540,
  },
  async (event) => {
    const filePath = event.data.name;
    const contentType = event.data.contentType;
    const bucket = storage.bucket(event.bucket);

    logger.info(`Processing file: ${filePath}`);

    // Exit if not an image
    if (!contentType || !contentType.startsWith("image/")) {
      logger.info("File is not an image, skipping");
      return null;
    }

    // Exit if already optimized (in thumbs folder)
    if (filePath.includes("/thumbs/") || filePath.includes("_optimized")) {
      logger.info("File is already optimized, skipping");
      return null;
    }

    // Exit if in temp folder
    if (filePath.startsWith("temp/")) {
      logger.info("File is in temp folder, skipping optimization");
      return null;
    }

    const fileName = path.basename(filePath);
    const fileDir = path.dirname(filePath);
    const tempFilePath = path.join(os.tmpdir(), fileName);

    try {
      // Download file to temp directory
      logger.info(`Downloading ${filePath} to ${tempFilePath}`);
      await bucket.file(filePath).download({destination: tempFilePath});

      // Generate thumbnail (200x200, WebP)
      const thumbFileName = `thumb_${fileName.split(".")[0]}.webp`;
      const thumbFilePath = path.join(os.tmpdir(), thumbFileName);

      await spawn("convert", [
        tempFilePath,
        "-thumbnail", "200x200^",
        "-gravity", "center",
        "-extent", "200x200",
        "-quality", "85",
        thumbFilePath,
      ]);

      // Upload thumbnail
      const thumbStoragePath = `${fileDir}/thumbs/${thumbFileName}`;
      logger.info(`Uploading thumbnail to ${thumbStoragePath}`);

      await bucket.upload(thumbFilePath, {
        destination: thumbStoragePath,
        metadata: {
          contentType: "image/webp",
          metadata: {
            original: filePath,
            type: "thumbnail",
          },
        },
      });

      // Generate optimized version (max 1920px width, WebP)
      const optimizedFileName = `${fileName.split(".")[0]}_optimized.webp`;
      const optimizedFilePath = path.join(os.tmpdir(), optimizedFileName);

      await spawn("convert", [
        tempFilePath,
        "-resize", "1920x1920>",
        "-quality", "85",
        optimizedFilePath,
      ]);

      // Upload optimized version
      const optimizedStoragePath = `${fileDir}/${optimizedFileName}`;
      logger.info(`Uploading optimized image to ${optimizedStoragePath}`);

      await bucket.upload(optimizedFilePath, {
        destination: optimizedStoragePath,
        metadata: {
          contentType: "image/webp",
          metadata: {
            original: filePath,
            type: "optimized",
          },
        },
      });

      // Get public URLs
      const thumbFile = bucket.file(thumbStoragePath);
      const optimizedFile = bucket.file(optimizedStoragePath);

      const [thumbUrl] = await thumbFile.getSignedUrl({
        action: "read",
        expires: "03-01-2500",
      });

      const [optimizedUrl] = await optimizedFile.getSignedUrl({
        action: "read",
        expires: "03-01-2500",
      });

      // Update Firestore based on file location
      await updateFirestoreWithOptimizedUrls(
        filePath,
        thumbUrl,
        optimizedUrl,
      );

      // Clean up temp files
      fs.unlinkSync(tempFilePath);
      fs.unlinkSync(thumbFilePath);
      fs.unlinkSync(optimizedFilePath);

      logger.info(`Image optimization complete for ${filePath}`);

      return {
        success: true,
        thumbnail: thumbStoragePath,
        optimized: optimizedStoragePath,
      };
    } catch (error) {
      logger.error("Error optimizing image:", error);

      // Clean up temp files on error
      try {
        if (fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);
      } catch (e) {
        // Ignore cleanup errors
      }

      return {success: false, error: error.message};
    }
  },
);

/**
 * Update Firestore documents with optimized image URLs
 * @param {string} originalPath - Original file path
 * @param {string} thumbUrl - Thumbnail URL
 * @param {string} optimizedUrl - Optimized image URL
 * @return {Promise<void>}
 */
async function updateFirestoreWithOptimizedUrls(
  originalPath,
  thumbUrl,
  optimizedUrl,
) {
  const db = admin.firestore();

  try {
    // Determine document type based on path
    if (originalPath.startsWith("profiles/")) {
      // Update user profile
      const userId = originalPath.split("/")[1];
      await db.collection("users").doc(userId).update({
        photoURL: optimizedUrl,
        thumbnailURL: thumbUrl,
        updatedAt: admin.firestore.Timestamp.now(),
      });

      logger.info(`Updated user ${userId} profile with optimized URLs`);
    } else if (originalPath.startsWith("stories/")) {
      // Update story document
      const userId = originalPath.split("/")[1];

      // Find story with matching mediaUrl
      const storiesQuery = await db.collection("stories")
        .where("userId", "==", userId)
        .where("mediaUrl", "==", originalPath)
        .limit(1)
        .get();

      if (!storiesQuery.empty) {
        const storyDoc = storiesQuery.docs[0];
        await storyDoc.ref.update({
          mediaUrl: optimizedUrl,
          thumbnailUrl: thumbUrl,
          updatedAt: admin.firestore.Timestamp.now(),
        });

        logger.info(`Updated story ${storyDoc.id} with optimized URLs`);
      }
    } else if (originalPath.startsWith("chats/")) {
      // Update message document with image
      const chatId = originalPath.split("/")[1];

      // Find message with matching imageUrl
      const messagesQuery = await db
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .where("imageUrl", "==", originalPath)
        .limit(1)
        .get();

      if (!messagesQuery.empty) {
        const messageDoc = messagesQuery.docs[0];
        await messageDoc.ref.update({
          imageUrl: optimizedUrl,
          thumbnailUrl: thumbUrl,
        });

        logger.info(`Updated message ${messageDoc.id} with optimized URLs`);
      }
    }
  } catch (error) {
    logger.error("Error updating Firestore with optimized URLs:", error);
  }
}
