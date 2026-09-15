# Product — LakeRover

LakeRover is an iPad-only companion app for an autonomous lake water-sampling rover built by the MCKK Robotics team. Tagline: "Dari Tasik ke Data. Dari Data ke Tindakan."

The app has four jobs:
1. **Live tracking** — show where the rover is, where it is going, and its health (battery, solar, link).
2. **Sampling** — walk a mission station by station, run the sampling process, and tag each cartridge.
3. **Data** — keep every sample record with sensor readings, show trends and a lake heat map, and export/share reports.
4. **Safer lakes** — surface alerts with a concrete next action, and let the operator stop or recall the rover at any time.

Primary users: students and teachers operating the rover during a mission, and judges/visitors during a demo. The app must be fully usable in **demo mode** with a simulated rover, because the hardware is not always available.

UI language is **Bahasa Malaysia** by default with English as a second language. All user-facing strings go through `Localizable.xcstrings`.

This build is a **demo for an idea competition**, not the production app. Optimise for a convincing 3-minute story in front of judges: the app must run fully offline with a simulated rover, and the AR rover model (built by students in Reality Composer) is the centrepiece of the pitch. A guided Showcase mode walks judges through Live → Sampling → AR → Insights.

The wireframe storyboard in `docs/wireframes/storyboard-v1.png` is the source of truth for screens and navigation. Follow it unless a spec says otherwise.
