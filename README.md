# Basis

**Math you can hold.** Bitrig Hacks, iPhone Duo.

Basis turns iPhone Duo into a physical coordinate system. Each inner panel carries one basis
direction, the hinge is their line of intersection, and the opening angle α *is* the geometry:

```
a = (1, 0, 0)    b = (cos α, 0, sin α)    h = (0, 1, 0)    B = [a b h]
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

## Demo Mode (five acts, one Next button)

1. **Phone = Matrix**: a and b start at the hinge, a × b lies along it (Swap reverses it), then
   B = [a b] maps the unit circle to an ellipse with semiaxes σ₁, σ₂. Area scale and κ collapse
   as the Duo flattens.
2. **Change the Basis**: a fixed vector p (preset, or streamed from a probe iPhone) keeps its
   position while c = B⁻¹p changes. Freeze Vector and Nudge show ill-conditioning. When the basis
   collapses, the app says "B⁻¹ does not exist" instead of showing infinities.
3. **Dual Space**: build p from arrows on one panel and measure it with covector contours
   (the rows of B⁻¹) on the other. The contours crowd together near singularity.
4. **Maps Between Spaces**: domain and codomain panels. Rotate, Shear, Stretch and Collapse morph
   the ellipse. Kernel and image light up for rank-deficient maps.
5. **Quantum**: the display normals are Bloch axes, and P(+) = (1 + n_A · n_B)/2. Flat gives
   100/0, 90° gives 50/50, and the seeded shots accumulate.

Explore Mode adds **Orthogonalize** (Gram–Schmidt / QR), **Reflections** (two mirror panels
compose into a rotation by 2φ about the hinge), **Orientation** (the outer face's normal is −n,
so its flux is −Φ), and **Surface** (intrinsic vs extrinsic distance).

## Outer display

The outer display is a second render target, not a second navigation stack. Lessons publish a
data-only `OuterScene` through the `OuterDisplayPresenting` protocol, and `OuterSceneView` renders
it. It has no menus, no controls, and shows one idea at a time. When the outer display is unavailable
(or **Calibration → Outer Display → Mode** is *Inner Only*), every lesson falls back to its
two-panel inner layout.

- **iOS 27.0 SDK:** uses `ExternalNonInteractiveAccessory`, and the system decides where it appears.
- **iOS 27.1 SDK:** add `BASIS_CAMERA_ACCESSORY` to the Swift active compilation conditions to use
  `CameraCaptureAccessory` (the Duo Greetings pattern). A front-camera session keeps it active,
  and its preview stays hidden behind the lesson.
- **Outer Preview** (Calibration) shows a live copy of the outer scene on the inner display, for
  development. Turn it off for judging.

## Architecture

```
App/
├── Root/        App shell, Explore home, Demo coordinator, lesson chrome, calibration
├── Duo/         HingeModel, device hinge adapter, calibration, two-panel layout
├── MathCore/    Pure math: BasisGeometry, ChangeOfBasis, DualBasis, GramSchmidt,
│                ReflectionComposition, QuantumMeasurement, LinearMap, IntrinsicGeometry
├── Lessons/     One folder per lab
├── Probe/       Headless ARKit tracking + calibration (no camera view)
├── Outer/       OuterScene, OuterDisplayState/Coordinator, accessory host, outer renderers
├── Networking/  Multipeer probe → Duo stream (~30 Hz JSON packets)
└── Visuals/     Canvas helpers, theme, equations, readouts
Tests/           Swift Testing suite for MathCore
```

All lesson math reads a single normalized quantity: α, the physical opening angle
(0° closed, 180° flat).

## Enabling the real hinge

The hinge API (`onHingeChange`) ships in the **iOS 27.1 SDK** (Xcode 27.1). Until then a clearly
labeled *simulated hinge* slider stands in so every lesson stays testable.

With Xcode 27.1:

1. Add `BASIS_DEVICE_HINGE` to the target's Swift active compilation conditions.
2. Run on the iPhone Duo simulator and open **Calibration**. Record fully open, right angle,
   and nearly closed. If the raw angle decreases as the device opens, set
   `HingeCalibration.convention = .foldAngle`.

## Probe iPhone

On an ordinary iPhone, open **Use This iPhone as a Probe**. Hold it upright facing you and tap
Recenter. Its calibrated displacement streams into the Change of Basis act on the Duo. If
networking fails, the preset vector is used automatically.
