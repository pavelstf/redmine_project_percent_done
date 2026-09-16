$ErrorActionPreference = "Stop"

$Candidates = @()
if ($env:REDMINE_PLUGIN_TEST_SKILL_ROOT) {
  $Candidates += $env:REDMINE_PLUGIN_TEST_SKILL_ROOT
}
$Candidates += (Join-Path $HOME ".codex/skills/redmine-plugin-test-runtime")
$Candidates += (Join-Path $PSScriptRoot "../../Codex-Skills/skills/redmine-plugin-test-runtime")
$SkillRoot = $Candidates | Where-Object { Test-Path -LiteralPath (Join-Path $_ "SKILL.md") } | Select-Object -First 1
if (-not $SkillRoot) {
  throw "redmine-plugin-test-runtime skill not found. Install it from pavelstf/Codex-Skills or set REDMINE_PLUGIN_TEST_SKILL_ROOT."
}

& (Join-Path $SkillRoot "scripts/run_redmine_plugin_tests.ps1") -PluginPath (Resolve-Path (Join-Path $PSScriptRoot "..")) @args
exit $LASTEXITCODE
