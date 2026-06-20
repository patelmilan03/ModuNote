{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    window.dispatchEvent(new Event('flutter-entrypoint-loaded'));
    let appRunner = await engineInitializer.initializeEngine({
      hostElement: window.document.querySelector("#flutter-host"),
    });
    window.dispatchEvent(new Event('flutter-engine-initialized'));
    await appRunner.runApp();
  },
});
