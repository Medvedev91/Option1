`brew edit --cask option1`

Update version and sha256 from GitHub.

Example:

```
cask "option1" do
  version "2026.10.26.57"
  sha256 "3424249531d08fb754c9b5ce8514807b3f42a588c19c3a7c42aab0560bfb17c4"

  url "https://github.com/Medvedev91/Option1/releases/download/v#{version}/Option1.dmg"
  name "Option1"
  desc "Two new features for macOS: 1. Open apps with shortcuts, like ⌥-1 for Chrome, ⌥-2 for Slack; 2. Open projects with shortcuts, like ⌥-3 for Option1.xcodeproj in Xcode. Any app."
  homepage "https://option1.io"
  app "Option1.app"
end
```

---

Setup

brew tap-new Medvedev91/Option1
brew create --cask --tap Medvedev91/Option1 https://github.com/Medvedev91/Option1/releases/download/v2026.10.26.57/Option1.dmg
