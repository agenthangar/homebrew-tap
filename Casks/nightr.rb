cask "nightr" do
  version "0.1.3"
  sha256 "f9d4ed8e680b722d8e6b92d61d577ed4221ce6315f6532ddf07457cb65db50df"

  url "https://github.com/agenthangar/nightr/releases/download/v#{version}/Nightr-#{version}-universal.dmg"
  name "Nightr"
  desc "Keep a Mac awake for coding-agent work"
  homepage "https://nightr.ai"
  depends_on macos: ">= :ventura"

  pkg "Nightr.pkg"
end
