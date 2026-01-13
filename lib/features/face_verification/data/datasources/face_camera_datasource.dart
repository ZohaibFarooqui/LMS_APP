import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Capture state machine for clean lifecycle management
///
/// Prevents race conditions, late frames, and camera surface crashes
enum CaptureState {
  /// Initial state - not capturing
  idle,

  /// Actively capturing frames
  capturing,

  /// Stopping capture - waiting for in-flight frames
  stopping,

  /// Capture completed - ready for finalization
  completed,
}

/// Data source for camera operations
///
/// Handles:
/// - Camera initialization
/// - Capturing images and frames
/// - Converting frames to images for backend
abstract class FaceCameraDataSource {
  /// Initialize camera
  Future<CameraController> initializeCamera();

  /// Capture image from camera
  Future<XFile> captureImage(CameraController controller);

  /// Capture burst of frames from camera stream
  ///
  /// Captures raw frames from camera and converts them to images.
  /// Returns list of full-frame images (not cropped).
  /// [onProgress] callback is called with frame count.
  Future<List<img.Image>> captureBurstFrames(
    CameraController controller,
    int numFrames, {
    void Function(int frameCount)? onProgress,
  });

  /// Dispose camera controller
  Future<void> disposeCamera(CameraController controller);
}

class FaceCameraDataSourceImpl implements FaceCameraDataSource {
  FaceCameraDataSourceImpl();

  @override
  Future<CameraController> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    // Use high resolution (1280x720) for better face detection accuracy
    // Fallback to medium if high is not supported
    ResolutionPreset resolutionPreset = ResolutionPreset.high;
    try {
      final controller = CameraController(
        frontCamera,
        resolutionPreset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();

      // Log actual resolution achieved
      debugPrint(
        'FaceCameraDataSource: Camera initialized - '
        'Resolution: ${controller.value.previewSize?.width}x${controller.value.previewSize?.height}, '
        'Sensor orientation: ${frontCamera.sensorOrientation}, '
        'Lens direction: ${frontCamera.lensDirection}',
      );

      return controller;
    } catch (e) {
      // Fallback to medium resolution if high is not supported
      debugPrint(
        'FaceCameraDataSource: High resolution not supported, falling back to medium: $e',
      );
      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();

      debugPrint(
        'FaceCameraDataSource: Camera initialized (medium) - '
        'Resolution: ${controller.value.previewSize?.width}x${controller.value.previewSize?.height}, '
        'Sensor orientation: ${frontCamera.sensorOrientation}',
      );

      return controller;
    }
  }

  @override
  Future<XFile> captureImage(CameraController controller) async {
    if (!controller.value.isInitialized) {
      throw StateError('Camera not initialized');
    }

    // Ensure image stream is stopped before taking picture
    // This is handled by the bloc, but adding safety check here
    try {
      return await controller.takePicture();
    } catch (e) {
      throw StateError('Failed to capture image: ${e.toString()}');
    }
  }

  /// Convert YUV420 CameraImage to RGB Image
  img.Image? _convertYUV420ToImage(CameraImage cameraImage) {
    try {
      final width = cameraImage.width;
      final height = cameraImage.height;

      if (cameraImage.planes.length < 3) {
        debugPrint(
          'FaceCameraDataSource: ERROR - Invalid YUV420 format, expected 3 planes, got ${cameraImage.planes.length}',
        );
        return null;
      }

      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];

      // Validate plane dimensions
      if (yPlane.bytesPerRow <= 0 || yPlane.bytes.isEmpty) {
        debugPrint(
          'FaceCameraDataSource: ERROR - Invalid Y plane: bytesPerRow=${yPlane.bytesPerRow}, '
          'bytes.length=${yPlane.bytes.length}',
        );
        return null;
      }

      // For YUV420, U and V planes are subsampled (half resolution)
      // Each UV sample corresponds to a 2x2 block of Y pixels
      final expectedUvWidth = width ~/ 2;
      final expectedUvHeight = height ~/ 2;

      debugPrint(
        'FaceCameraDataSource: YUV conversion - Image: $width x $height, '
        'Y plane: bytesPerRow=${yPlane.bytesPerRow}, bytes.length=${yPlane.bytes.length}, '
        'expected height=${(yPlane.bytes.length / yPlane.bytesPerRow).ceil()}, '
        'U plane: bytesPerRow=${uPlane.bytesPerRow}, bytes.length=${uPlane.bytes.length}, '
        'V plane: bytesPerRow=$vPlane.bytesPerRow, bytes.length=${vPlane.bytes.length}, '
        'Expected UV size: ${expectedUvWidth}x$expectedUvHeight',
      );

      // Create RGB image
      final image = img.Image(width: width, height: height);

      // Convert YUV to RGB
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          try {
            final yIndex = y * yPlane.bytesPerRow + x;

            // Ensure indices are within bounds
            if (yIndex >= yPlane.bytes.length) {
              debugPrint(
                'FaceCameraDataSource: ERROR - Y plane index out of bounds: $yIndex >= ${yPlane.bytes.length}',
              );
              continue;
            }

            // For YUV420 format, U and V planes are subsampled (half resolution)
            // Each UV sample corresponds to a 2x2 block of Y pixels
            final uvRow = y ~/ 2;
            final uvCol = x ~/ 2;

            // Calculate UV indices with proper bounds checking
            int uValue = 128; // Default neutral U (gray)
            int vValue = 128; // Default neutral V (gray)

            // Calculate U plane index
            if (uPlane.bytesPerRow > 0 &&
                uvRow < (uPlane.bytes.length / uPlane.bytesPerRow).ceil()) {
              final uIndex = uvRow * uPlane.bytesPerRow + uvCol;
              if (uIndex >= 0 && uIndex < uPlane.bytes.length) {
                uValue = uPlane.bytes[uIndex];
              }
            }

            // Calculate V plane index
            if (vPlane.bytesPerRow > 0 &&
                uvRow < (vPlane.bytes.length / vPlane.bytesPerRow).ceil()) {
              final vIndex = uvRow * vPlane.bytesPerRow + uvCol;
              if (vIndex >= 0 && vIndex < vPlane.bytes.length) {
                vValue = vPlane.bytes[vIndex];
              }
            }

            final yValue = yPlane.bytes[yIndex];

            // YUV to RGB conversion
            final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
            final g = (yValue - 0.344 * (uValue - 128) - 0.714 * (vValue - 128))
                .clamp(0, 255)
                .toInt();
            final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

            // Set pixel with RGBA values directly
            image.setPixelRgba(x, y, r, g, b, 255);
          } catch (e) {
            // Skip this pixel if conversion fails
            debugPrint(
              'FaceCameraDataSource: Error converting pixel at ($x, $y): $e',
            );
            continue;
          }
        }
      }

      debugPrint('FaceCameraDataSource: Successfully converted YUV420 to RGB');
      return image;
    } catch (e, stackTrace) {
      debugPrint('FaceCameraDataSource: ERROR in _convertYUV420ToImage - $e');
      debugPrint('FaceCameraDataSource: Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<List<img.Image>> captureBurstFrames(
    CameraController controller,
    int numFrames, {
    void Function(int frameCount)? onProgress,
  }) async {
    final frames = <img.Image>[];
    int capturedFrames = 0;

    CaptureState captureState = CaptureState.idle;

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (_) {}

    final completer = Completer<void>();
    captureState = CaptureState.capturing;

    try {
      await controller.startImageStream((CameraImage image) {
        if (captureState != CaptureState.capturing) return;

        Future.microtask(() async {
          if (captureState != CaptureState.capturing) return;

          try {
            // Convert CameraImage to RGB Image (full frame, not cropped)
            final rgbImage = _convertYUV420ToImage(image);
            if (rgbImage == null) {
              debugPrint(
                'FaceCameraDataSource: Failed to convert frame to RGB',
              );
              return;
            }

            frames.add(rgbImage);
            capturedFrames++;

            onProgress?.call(capturedFrames);

            debugPrint(
              'FaceCameraDataSource: Captured frame $capturedFrames/$numFrames',
            );

            // Stop when we have enough frames
            if (capturedFrames >= numFrames && !completer.isCompleted) {
              captureState = CaptureState.stopping;
              try {
                await controller.stopImageStream();
              } catch (_) {}
              captureState = CaptureState.completed;
              completer.complete();
            }
          } catch (e) {
            debugPrint('FaceCameraDataSource: Error processing frame: $e');
          }
        });
      });

      // Set a timeout to prevent infinite waiting
      await completer.future.timeout(
        Duration(seconds: 10),
        onTimeout: () {
          debugPrint(
            'FaceCameraDataSource: Capture timeout - captured ${frames.length} frames',
          );
          captureState = CaptureState.stopping;
          controller.stopImageStream();
          captureState = CaptureState.completed;
        },
      );
    } catch (e) {
      debugPrint('FaceCameraDataSource: Burst capture error: $e');
    } finally {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {}

      captureState = CaptureState.completed;
    }

    debugPrint(
      'FaceCameraDataSource: Burst capture completed - ${frames.length} frames',
    );
    return frames;
  }

  @override
  Future<void> disposeCamera(CameraController controller) async {
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}

    await controller.dispose();
  }
}
