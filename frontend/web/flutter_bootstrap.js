{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    // Remove splash screen
    const loadingEl = document.getElementById('loading');
    if (loadingEl) {
      loadingEl.remove();
    }
    await appRunner.runApp();
  }
});
