// Constants for the BloodLine app

// Update state enum for AppUpdater
enum UpdateState {
  idle,
  checking,
  available,
  downloading,
  downloaded,
  installing,
  error,
  permissionDenied,
}
