import 'main_hosted.dart' as hosted;

void main() {
  // Default entry point boots hosted mode so the module's baseline path
  // stays aligned with native embedding.
  hosted.runHostedApp();
}
