<p align="center">
  <img src="Assets/logo-512.png" alt="Aurora" width="280">
</p>

# Aurora

Make any view glow. A band of light travels the border of your cards, buttons and text fields. One line,
SwiftUI or UIKit.

```swift
CardView()
    .aurora(.regular, in: .rounded(cornerRadius: 20))
```

## See it

<p align="center">
  <img src="Assets/ex1.gif" alt="The regular preset sweeping the border of a card" width="440"><br>
  <sub><code>.regular</code> — a band of light sweeps the whole border, with <code>showsBorder</code> tracing the edge it travels</sub>
</p>

<p align="center">
  <img src="Assets/ex2.gif" alt="The underline preset lighting a focused text field" width="440"><br>
  <sub><code>.underline</code> — the bottom edge only, bound to <code>@FocusState</code> so it lights while the field holds the caret</sub>
</p>

<p align="center">
  <img src="Assets/ex3.gif" alt="The pulseOutward preset breathing a halo around a tile" width="270"><br>
  <sub><code>.pulseOutward</code> — breathes past the bounds as an uncropped halo, here on a light appearance</sub>
</p>

## Requirements

iOS 17, macOS 14, tvOS 17 or visionOS 1. Swift 6, no dependencies, no resource bundle.

Built and tested against iOS and macOS. tvOS and visionOS are declared but not yet exercised.

## Install

```swift
dependencies: [
    .package(url: "https://github.com/marciliojrs/aurora.git", from: "1.0.0")
]
```

Add the **`Aurora`** product and `import Aurora`. That is everything: SwiftUI and UIKit in one module, with
the configuration types included.

<sub>There is also an <code>AuroraCore</code> product, for the rare case of driving <code>AuroraSceneBuilder</code> into a renderer of your
own. You do not need it otherwise.</sub>

## SwiftUI

Attach the modifier, or wrap the view:

```swift
import Aurora

CardView()
    .aurora(.regular, in: .rounded(cornerRadius: 20))

Aurora(.regular, in: .rounded(cornerRadius: 20)) {
    CardView()
}
```

Drive it from state, and get told when each fade finishes:

```swift
CardView()
    .aurora(
        .pulseInward,
        in: .rounded(cornerRadius: 20),
        isActive: viewModel.isProcessing,
        onActivate: { analytics.log(.auroraShown) },
        onDeactivate: { analytics.log(.auroraHidden) }
    )
```

## UIKit

```swift
import Aurora

button.addAurora(.compact, in: .capsule)
field.addAurora(.underline, in: .rounded(cornerRadius: 14))
```

`addAurora` wraps the view in place and re-points any constraints that referenced it, so a view that is
already installed survives it. Building a hierarchy from scratch instead? Make the wrapper directly:

```swift
let glow = AuroraView(
    contentView: card,
    configuration: AuroraStyle.standard.configuration(.pulseOutward, in: .rounded(cornerRadius: 20))
)
view.addSubview(glow)

glow.isActive = viewModel.isProcessing
```

## Presets

| Preset | Motion | Reach for it when |
|---|---|---|
| `.compact` | Light sweeps the border | Buttons, chips, toggles, anything control-sized |
| `.regular` | Light sweeps the border | Cards, panels, sheets. The default |
| `.underline` | Light travels the bottom edge | Text fields and search bars |
| `.pulseInward` | Breathes inside the border | Reporting an ongoing state |
| `.pulseOutward` | Breathes as an outward halo | Pulling attention to a whole card |

### `.compact` vs `.regular`

Same motion, two separate tunings, because a 1pt ring on a 40pt button has different problems from the same
ring on a 180pt card. `.compact` gives you a brighter border and a weaker inward glow, so the effect carries
on a short perimeter without washing over the label. Its bright arc is wider, since the head crosses a small
control fast enough that a narrow arc would read as a blink. And its blobs scale with the host, so one preset
looks right on a chip and on a wide button.

**Which to pick:** go by height, not by what the element is called. Under roughly 60pt, `.compact`. A card is
`.regular` even when it is small; a tall button is still `.compact`. If the glow inside the border competes
with the label, you want `.compact`.

### `.pulseOutward` needs an opaque view

It draws behind the content and spills past the bounds, so:

- Give the wrapped view an opaque background, or the halo shows through the middle.
- Keep `clipsToBounds` off on ancestors. In SwiftUI, leave room with `.padding()` so a neighbouring row does
  not sit on top of it.

## Shapes

`in:` takes a shape, not a number:

| Shape | Traces |
|---|---|
| `.rounded(cornerRadius: 20)` | A rounded rectangle. Square corners are radius `0` |
| `.capsule` | Fully rounded on the short axis. Circles too |
| `.preset` | The preset's own radius. The default |

Name the same shape the view is clipped to. `.capsule` needs no arithmetic and stays correct as the view
resizes, which a hardcoded radius will not:

```swift
Button("Summarise", action: summarise)
    .padding(.horizontal, 20)
    .frame(height: 40)
    .background(.fill, in: .capsule)
    .aurora(.compact, in: .capsule)
```

## Colors

Three cases, and the colors are yours:

```swift
.aurora(.regular, in: .rounded(cornerRadius: 20), colorVariant: .glow)
.aurora(.regular, in: .rounded(cornerRadius: 20), colorVariant: .tinted(brandBlue))
.aurora(.regular, in: .rounded(cornerRadius: 20), colorVariant: .multiColor([teal, indigo]))
```

| Case | Draws |
|---|---|
| `.glow` | The full spectrum. The default |
| `.tinted(_:)` | One hue, held still rather than drifted |
| `.multiColor(_:)` | Several hues, dealt across the border in order and repeating |

`.neutral`, `.cool` and `.warm` are ready-made values built on those — `.neutral` is `.tinted(.white)`.

Your hue is multiplied through the palette rather than replacing it, so the border keeps reading as separate
pools of light instead of one flat band. Every palette is tuned twice, once per appearance, so a tint works on
a white card and a dark one with nothing extra from you.

## Styling a whole app

Palette, appearance, intensity and tempo come from an `AuroraStyle` in the environment, so a reusable
component can attach a glow without deciding how your app looks:

```swift
// The component. Says where the glow goes, and nothing about the colors.
struct SummariseButton: View {
    var body: some View {
        Text("Summarise")
            .padding(.horizontal, 20)
            .frame(height: 40)
            .background(.fill, in: .capsule)
            .aurora(.compact, in: .capsule)
    }
}

// Your app. Answers the color question once, for everything below.
RootView()
    .auroraStyle(AuroraStyle(colorVariant: .tinted(brandBlue), strength: 0.8))
```

Override per call where one view has to differ, or adjust part of the inherited style for a subtree:

```swift
DeleteButton().aurora(.compact, in: .capsule, colorVariant: .tinted(destructiveRed))

SettingsList().auroraStyle(strength: 0.5)   // keeps the inherited palette
```

UIKit has no environment, so hold a style and pass it:

```swift
let style = AuroraStyle(colorVariant: .tinted(brandBlue), strength: 0.8)
button.addAurora(.compact, in: .capsule, style: style)
```

## Borders

If the view has no border of its own, the sweep has nothing to travel along and reads as an edge appearing
and vanishing. `showsBorder` traces the outline and lets the effect light it:

```swift
CardView()
    .aurora(.regular, in: .rounded(cornerRadius: 20), showsBorder: true)
```

White on dark, grey on light, and it appears only where the light is — no resting hairline boxing in your
view. For `.compact` and `.regular` it sweeps in step with the glow.

## More examples

A text field that glows while it holds the caret:

```swift
@FocusState private var isFocused: Bool

TextField("Ask a question", text: $query)
    .focused($isFocused)
    .padding(.horizontal, 16)
    .frame(height: 48)
    .background(.fill, in: .rect(cornerRadius: 14))
    .aurora(.underline, in: .rounded(cornerRadius: 14), isActive: isFocused)
```

A card reporting a long-running job. `.pulseInward` breathes without travelling, which reads as a state
rather than as progress:

```swift
Aurora(.pulseInward, in: .rounded(cornerRadius: 20), isActive: job.isRunning) {
    JobStatusCard(job: job)
        .background(.background.secondary, in: .rect(cornerRadius: 20))
}
```

A halo pulling the eye to one card in a list:

```swift
ForEach(results) { result in
    ResultCard(result: result)
        .background(.background.secondary, in: .rect(cornerRadius: 20))
        .aurora(.pulseOutward, in: .rounded(cornerRadius: 20), isActive: result.isRecommended)
        .padding(.vertical, result.isRecommended ? 24 : 0)
}
```

## Options

Every optional means "use the preset's tuned value" rather than one global default.

| Property | Default | Notes |
|---|---|---|
| `size` | `.regular` | Which preset |
| `colorVariant` | `.glow` | Which palette |
| `theme` | `.auto` | Follows the surrounding color scheme |
| `shape` | `.preset` | The outline to trace |
| `showsBorder` | `false` | Traces the view's outline and lights it |
| `borderWidth` | preset | Ring thickness in points |
| `duration` | preset | Seconds per cycle |
| `strength` | `1` | Overall intensity, `0...1`. Never touches your content |
| `brightness` | preset | Multiplicative |
| `saturation` | preset | |
| `hueRange` | `30°` | Drift either side of the base hue |
| `staticColors` | `false` | Freezes the hue animation |

Pass a whole `AuroraConfiguration` when it is computed or held in a view model. That form ignores the
inherited style:

```swift
CardView().aurora(configuration: viewModel.auroraConfiguration)
```

## Accessibility

Under Reduce Motion the glow stays visible and stops moving, settling on a representative frame. Removing it
would change what the layout communicates, not only how it animates.

The effect is decorative throughout: it disables hit testing, so taps reach your content, and it stays hidden
from assistive technologies.

## Snapshot testing

The glow advances every frame, so pin the clock:

```swift
let renderer = ImageRenderer(
    content: CardView()
        .aurora(.regular, in: .rounded(cornerRadius: 20))
        .auroraClockFrozen(at: 0.98)
)
```

Freezing also treats the fade-in as finished, so one pass renders a fully visible glow.

Pick the instant carefully for `.underline`: its edge fade sits at zero early in the cycle, so freezing near
zero captures an empty frame. Choose something between 33% and 67% of the duration.

## Performance

- Breathing presets sample at 30 Hz rather than at every display refresh.
- The wide halo is frozen at the average of its breathing range, so the most expensive layer rasterizes once.
- Offscreen glows stop, and an inactive glow stops its clock once it has finished fading out.

## Running the examples

Previews need no project. Open the package in Xcode and use `Sources/Aurora/Previews.swift`, or
`UIKitPreviews.swift` for the UIKit surface:

```sh
open .
```

For live controls over palette, tint, intensity, appearance and the activation fade, run a demo app:

```sh
open Examples/AuroraExamples.xcodeproj
```

Two schemes, `AuroraSwiftUIExample` and `AuroraUIKitExample`. Each is a list of the five presets, with one
screen per preset holding the effect and its controls together.

## Credits

Inspired by the Border Beam Effect from Kavsoft:
[youtube.com/watch?v=DHqLSjgBNPY](https://www.youtube.com/watch?v=DHqLSjgBNPY)

## License

MIT.
