# ☕ SwiftBar Caffeinate Toggle

A [SwiftBar](https://swiftbar.app/) plugin to control macOS [`caffeinate`](https://ss64.com/osx/caffeinate.html) directly from the menu bar.

Keep your Mac **awake for SSH, Docker, or long-running tasks** while letting the display sleep.
Supports **indefinite mode**, **timed sessions**, **safe process tracking**, and **battery warnings**.

---

## ✨ Features

- ✅ **Toggle keep-awake** (indefinite mode)
- ✅ **Timed sessions**: 1h / 4h / 8h
- ✅ **Countdown timer** in the menu bar
- ✅ **Safe PID tracking** → only manages its own `caffeinate`
- ✅ **External detection** → shows if another caffeinate process is running
- ✅ **Turn display off now** without stopping system awake
- ✅ **Stop + Turn display off** in one click
- ✅ **Battery warnings** if awake mode is running on battery

---

## 📸 Screenshots

*(Add screenshots of menu bar and dropdown here)*

---

## 🔧 Installation

1. Install [SwiftBar](https://swiftbar.app/).
2. Choose or create a **Plugins folder** (Preferences → General).
3. Copy the plugin into your folder as `swiftbar-caffeinate-toggle.1m.sh`
4. Make it executable: `chmod +x ~/SwiftBarPlugins/swiftbar-caffeinate-toggle.1m.sh`
5. SwiftBar will auto-detect it and show ☕ / 💤 in your menu bar.

---

## ⚙️ Usage

* Menu bar title
  * ☕ Keep Awake — caffeinate running
  * ☕ Keep Awake (external) — caffeinate detected outside plugin
  * 💤 Auto-sleep — no caffeinate running
* Dropdown options
  * Toggle → start/stop indefinite keep-awake
  * Stop Keep Awake → stop only
  * Stop & Turn Display Off Now → stop caffeinate and immediately blank screen
  * Restart Indefinite → stop + restart a fresh session
  * Timed sessions → 1h / 4h / 8h (with live countdown in menu bar)
  * Turn Display Off Now → blank screen while leaving system state unchanged
* Battery Warning
  * If keep-awake is active on battery, the menu shows:
    ```
    ⚠️ Running on battery — consider plugging in.
    ```

---

## 📜 License

MIT License — free to use, modify, and share.