![Hero image showing the configuration abilities of IMGLYUI](https://img.ly/static/cesdk_release_header_ios.png)

# IMGLY UI

This package contains the Swift version of the IMG.LY UI for the _Creative Engine_, the UI for CE.SDK.
The Creative Engine enables you to build any design editing UI, automation and creative workflow in Swift.
It offers performant and robust graphics processing capabilities combining the best of layout, typography and image processing with advanced workflows centered around templating and adaptation.

The Creative Engine seamlessly integrates into any iOS app whether you are building a photo editor, template-based design tool or scalable automation of content creation for your app.

Visit our [documentation](https://img.ly/docs/cesdk) for more tutorials on how to integrate and
customize the engine for your specific use case.

## License

The CreativeEditor SDK is a commercial product. To use it and get access you need to unlock the SDK with a license file. You can purchase a license at https://img.ly/pricing.

## Integration

### SwiftUI

```Swift
import IMGLYDesignEditor // IMGLYVideoEditor, IMGLYApparelEditor, IMGLYPostcardEditor, or IMGLYCamera
import SwiftUI

struct IntegrateWithSwiftUI: View {
  var body: some View {
    NavigationView {
      DesignEditor(.init(license: secrets.licenseKey, userID: "<your unique user id>"))
    }
  }
}
```

## Documentation

The IMGLYUI package consists of the [mobile editor](https://img.ly/docs/cesdk/mobile-editor/quickstart?platform=ios) and the [mobile camera](https://img.ly/docs/cesdk/mobile-camera/quickstart?platform=ios). The full documentation can be found on our website.
There you will learn how to integrate and configure them for your use case.

## Changelog

To keep up-to-date with the latest changes, visit [CHANGELOG](https://img.ly/docs/cesdk/web/faq/changelog/).
