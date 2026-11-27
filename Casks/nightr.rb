cask "nightr" do
  version "0.1.4"
  sha256 "20b5aca33ce9cf631c4a6225ac6506cd7cb24e7280bf8f4cc883596cf48063ed"

  url "https://github.com/agenthangar/nightr/releases/download/v#{version}/Nightr-#{version}-universal.dmg"
  name "Nightr"
  desc "Keep a Mac awake for coding-agent work"
  homepage "https://nightr.ai"
  depends_on macos: ">= :ventura"

  pkg "Nightr.pkg"
end
