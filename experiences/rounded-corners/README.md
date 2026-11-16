# Rounded Corners

An interactive walkthrough of how Roblox draws modern 2D UI: shadows, gradients, and rounded corners. It starts with a sword shop menu, then breaks down the techniques behind it one scene at a time.

## Scenes

1. **Sword shop:** the finished menu over a small 3D scene.
1. **Shadow workarounds:** a baked PNG shadow and stacked `UIStroke` rings next to `UIShadow`, as the frame changes size.
1. **Anatomy of a shadow:** how `UIShadow` builds a soft shadow, step by step.
1. **Changing the frame:** the shadow tracking corner radius, size, and rotation changes.
1. **Gradient types:** `Linear`, `Radial`, and `Conical` `UIGradient` types side by side.
1. **The full menu:** the shop menu again, with every effect in play.

## Playgrounds

Two hands-on playgrounds sit outside the numbered scenes. Open them from the buttons in the top-right corner, and return with **Back to the demo**.

- **Shadow playground:** a frame with a real `UIShadow`. Change its `BlurRadius`, `Offset`, `Transparency`, and `Spread`, add a second shadow behind it, and change the frame's corner radius, size, and rotation. **Load the sword shop shadows** fills in the shop menu's two layers.
- **Gradient playground:** a frame with a real `UIGradient`. Switch its `Type` between `Linear`, `Radial`, and `Conical`, try a few colors and a fade, and change `Rotation`, `Offset`, and `Scale`. **Load the sword shop header** fills in the shop menu's header gradient.

Each playground starts from the modifier's default settings and shows values the way Studio's Properties window does. The layout adapts to the window: the controls sit beside the frame in wide windows and under it in narrow ones, and they work with touch.

## Controls

The on-screen ‹ and › buttons in the bottom-right corner step through the scenes, so the demo works with touch. On a keyboard:

| Key | Action |
| --- | --- |
| `1` to `6` | Jump to a scene |
| Left / Right | Previous or next step, then scene |
| Space | Pause or resume |
| `R` | Restart the current scene |
| `H` | Hide or show captions and on-screen buttons, for clean recordings |
| `B` | Toggle background blur in 3D scenes |

## Run it

Open `RoundedCorners.rbxl` in Studio and click **Play**.

To edit the code with Rojo, run `rojo serve` from this folder, open `RoundedCorners.rbxl`, and connect from the Rojo plugin. All of the code lives in the `RoundedCornerDemo` LocalScript under `StarterPlayerScripts`. It builds the UI, the 3D scene, and the lighting at runtime. Each scene is a module in `Scenes`, and both playgrounds share the layout in `Playground.luau`.

## Requirements

The demo uses `UIShadow` and the `Radial` and `Conical` gradient types. If your Studio version doesn't support them yet, a warning appears at the top of the screen.

The shadow workarounds scene generates its PNG shadow at runtime with `EditableImage`. This works in Studio, but a published experience also needs **Allow Mesh / Image APIs** turned on in **Experience Settings > Security**. Without it, the PNG shadow is missing and the scene shows a warning. You can also upload your own shadow image and set `ShadowImage` in `Config.luau` instead.

## Configuration

`Config.luau` has a few options:

- `ShadowImage`: the image for the PNG shadow in the shadow workarounds scene. Leave it empty to generate the shadow at runtime, or set it to an uploaded asset ID.
- `StageSize`: the design resolution. The stage scales to fit any window size.
- `ShowCaptions`: whether captions show on start.
- `StartScene`: the scene to open first.
