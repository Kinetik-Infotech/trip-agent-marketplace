# Trip Agent

A free trip planner plugin for Claude, from Kinetik. It runs in your own Claude account, so you need a paid Claude plan, such as Pro or Max. It learns your taste from pairs of hotel photos, then finds places, hotels and flights that suit you, at your pace. What it learns about you stays on your computer and in your own Claude account.

## Install

On a Mac, paste this into the Terminal in the Claude app's Code tab:

```bash
curl -fsSL https://raw.githubusercontent.com/Kinetik-Infotech/trip-agent-marketplace/main/install/install.sh | bash
```

On Windows, paste this into PowerShell:

```powershell
irm https://raw.githubusercontent.com/Kinetik-Infotech/trip-agent-marketplace/main/install/install.ps1 | iex
```

The installer adds the plugin to Claude and makes your travel folder, `trip-agent`, in your home folder. Start a new Code session on that folder and type "Plan me a trip".

To add the plugin by hand instead:

```bash
claude plugin marketplace add Kinetik-Infotech/trip-agent-marketplace
claude plugin install trip-agent@trip-agent
```

## Travel connectors

Trip Agent searches with the connectors in your own Claude account. Add Tripadvisor, Kiwi.com and Brek in the Claude app under Settings, then Connectors. Civitatis, Veltra and AccuWeather are optional.

Trip Agent never books or takes payment. It gives you links to book on the provider's own site.

More at [tripagent.me](https://tripagent.me).
