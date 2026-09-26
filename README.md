# Basis

**Math you can hold.** Bitrig Hacks, iPhone Duo.

Basis turns iPhone Duo into a physical coordinate system. Each inner panel carries one basis
direction, the hinge is their line of intersection, and the opening angle α *is* the geometry:

```
a = (1, 0, 0)    b = (cos α, 0, −sin α)    h = (0, 1, 0)    B = [a b h]
```

> The phone is not controlling the matrix. The phone is the matrix.
>
> **Inside is the construction. Outside is the consequence.**

| Inner display | Outer display |
|---|---|
| physical basis a, b | B(unit circle): ellipse, σ₁, σ₂, κ |
| fixed vector p + changing basis | coordinates B⁻¹p |
| primal space V | dual measurement grid V* |
| domain V | codomain W, im(A) |
| preparation + measurement axes | shots + histogram |
| inner normal n, flux Φ | outer normal −n, flux −Φ |

## Demo Mode (five acts, 90–120 seconds, launches directly)

1. **Directions, not matrices**: the two halves are two directions you're allowed to travel, and
   the hinge gives a third. A glowing tracer walks the route to P along each physical panel,
   then the notation follows: `p = 1.4 a + 0.8 b + 0.3 h`, then `[p]_B = (1.4, 0.8, 0.3)`.
2. **Hold the point**: the probe iPhone *is* P. Move it and the route updates. Leave it still and
   rotate the whole Duo: the point didn't move, the frame did, so the coordinates changed.
3. **Break the basis**: fold a and b toward each other. Reaching the same point now takes two
   long journeys that nearly cancel (ill-conditioning). Outside, the reachable region and the
   effort ellipse collapse to a line: *One Dimension Lost*.
4. **The rulers behind coordinates**: the dual basis as measuring rulers (level lines). Near
   singularity they pack together and become absurdly sensitive.
5. **Quantum payoff**: the screen normals are Bloch axes, and P(+) = (1 + n_A · n_B)/2. Flat gives
   100/0 and 90° gives 50/50; the shots appear on the outside.

Explore Mode (toolbar) adds Maps, Orthogonalize, Reflections, Flux and Surface.

## Outer display

The outer display is a second render target, not a second navigation stack. Lessons publish a
data-only `OuterScene` through the `OuterDisplayPresenting` protocol, and `OuterSceneView` renders
it. It has no menus, no controls, and shows one idea at a time. When the outer display is unavailable
(or **Calibration → Outer Display → Mode** is *Inner Only*), every lesson falls back to its
two-panel inner layout.

- **iOS 27.1+ SDK:** uses `CameraCaptureAccessory` (the Duo Greetings pattern). A front-camera
  session keeps it active on devices with a hinge, and its preview stays hidden behind the lesson.
  It pauses while the phone is acting as the probe.
- **iOS 27.0 SDK:** falls back to `ExternalNonInteractiveAccessory`.
- **Outer Preview** (Calibration) shows a live copy of the outer scene on the inner display, for
  development. Turn it off for judging.

## Architecture

```
App/
├── Root/        App shell, Explore home, Demo coordinator, lesson chrome, calibration
├── Duo/         Hinge, attitude (deviceMotionBody), calibration, fold-aware two-panel layout
├── MathCore/    Pure math: BasisGeometry, CoordinateSolver, CoordinateRoute, DualBasis,
│                GramSchmidt, ReflectionComposition, QuantumMeasurement, OrientedFlux, LinearMap
├── Lessons/     One folder per lab
├── Probe/       Headless ARKit tracking + calibration (no camera view)
├── Outer/       OuterScene, OuterDisplayState/Coordinator, accessory host, outer renderers
├── Networking/  Multipeer probe → Duo stream (~30 Hz JSON packets)
└── Visuals/     Canvas helpers, theme, equations, readouts
Tests/           Swift Testing suite for MathCore
```

All lesson math reads a single normalized quantity: α, the physical opening angle
(0° closed, 180° flat).

## Duo APIs and SDKs

Build with **Xcode 27.2 beta** (Bitrig → Settings → Xcode). The project also compiles with Xcode
27.0: every 27.1+ API is gated on the SDK's SwiftUI module version (`canImport(SwiftUI, _version: 8.1)`),
so older SDKs fall back to the simulated hinge and the inner-only layout.

- **Hinge:** `onHingeChange` drives α. Open **Calibration**, record fully open, right angle, and nearly
  closed. If the raw angle decreases as the device opens, set `HingeCalibration.convention = .foldAngle`.
- **Layout:** the split follows the fold's `division` reserved region (queried even while inactive).
- **Attitude:** a hidden view on panel A is CoreMotion's `deviceMotionBody` (iOS 27), so frame rotation
  refers to that panel. **Calibration → Attitude** shows exactly what the device or simulator exposes.
  If no samples arrive, Hold the Point uses a clearly labeled demo control, never described as sensed.

## Probe iPhone

On an ordinary iPhone, open **Use This iPhone as a Probe**. Hold it upright facing you and tap
Set Origin. Its calibrated displacement streams into the Change of Basis act on the Duo. If
networking fails, the preset vector is used automatically.
