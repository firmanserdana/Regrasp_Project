# Third-Party Components

The MIT license in [`LICENSE`](LICENSE) covers the original code in this
`Code/` folder. Some subfolders bundle or depend on third-party software that
is **not** owned by this project and remains under its own license terms:

| Component | Location | Origin / License |
|---|---|---|
| Xippmex / Xipppy SDK | `Characterization/xippmex/`, `Regrasp_Dependency/Xippmex/`, `Regrasp_Dependency/Xipppy/` | Ripple Neuromed Trellis SDK — proprietary, vendor license |
| MediaPipe | `mediapipe/` (Python scripts depend on the `mediapipe` package) | Google, Apache-2.0 (installed as a pip dependency, not vendored) |
| MATLAB App Designer / Toolboxes | `.mlapp` files under `Characterization/`, `Control/` | Require licensed MATLAB + relevant toolboxes (Instrument Control, Signal Processing, etc.) |
| Arduino libraries | `Control/Control v2/Arduino code/` | Third-party Arduino/vendor libraries where applicable — see individual file headers |

If you plan to redistribute or archive (e.g., on Zenodo) any of the
vendor-provided folders above, confirm you are permitted to do so under the
vendor's terms, or exclude them from the archive and note them as external
dependencies instead.
