param(
  [string]$RuntimeRoot = "C:\RedmineTestRuntimes\redmine-6.1.2",
  [string]$PluginPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$Ruby = Join-Path $RuntimeRoot ".ruby\3.3.11-1\rubyinstaller-3.3.11-1-x64\bin\ruby.exe"
if (-not (Test-Path -LiteralPath $Ruby)) {
  throw "Ruby not found: $Ruby"
}

$TmpDir = Join-Path $PluginPath "tmp"
New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null

$RubyScript = Join-Path $TmpDir "check_period_type_migrations.rb"
$DatabasePath = Join-Path $TmpDir "period_type_migration_check.sqlite3"

@'
require "bundler/setup"
require "active_record"
require "logger"
require "fileutils"

plugin_path = ENV.fetch("PLUGIN_PATH")
database_path = ENV.fetch("DATABASE_PATH")

require File.join(plugin_path, "db/migrate/001_create_project_percent_done_history")
require File.join(plugin_path, "db/migrate/002_add_period_type_to_project_percent_done_snapshots")

def connect(database_path)
  ActiveRecord::Base.connection.disconnect! if ActiveRecord::Base.connected?
  FileUtils.rm_f(database_path)
  ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => database_path)
  ActiveRecord::Base.logger = Logger.new(nil)
end

def connection
  ActiveRecord::Base.connection
end

def create_projects_table
  connection.create_table(:projects) do |t|
    t.string :name
  end
end

def unique_index_columns(name)
  index = connection.indexes(:project_percent_done_snapshots).detect { |candidate| candidate.name == name }
  raise "missing index #{name}" unless index
  raise "index #{name} is not unique" unless index.unique
  index.columns
end

def assert(condition, message)
  raise message unless condition
end

connect(database_path)
create_projects_table
CreateProjectPercentDoneHistory.migrate(:up)
AddPeriodTypeToProjectPercentDoneSnapshots.migrate(:up)

columns = connection.columns(:project_percent_done_snapshots).map(&:name)
assert(columns.include?("period_type"), "fresh install missing period_type")
assert(unique_index_columns("idx_ppd_snapshots_project_period") == %w[project_id period_type period_end],
       "fresh install unique index is not project_id + period_type + period_end")
puts "fresh_install=ok"

connect(database_path)
connection.create_table(:project_percent_done_snapshots) do |t|
  t.integer :project_id, :null => false
  t.date :period_end
end
connection.add_index(:project_percent_done_snapshots, [:project_id, :period_end],
                     :unique => true, :name => "idx_ppd_snapshots_project_period")
connection.execute("INSERT INTO project_percent_done_snapshots (project_id, period_end) VALUES (1, '2026-07-26')")

AddPeriodTypeToProjectPercentDoneSnapshots.migrate(:up)

columns = connection.columns(:project_percent_done_snapshots).map(&:name)
assert(columns.include?("period_type"), "upgrade missing period_type")
assert(unique_index_columns("idx_ppd_snapshots_project_period") == %w[project_id period_type period_end],
       "upgrade unique index is not project_id + period_type + period_end")
values = connection.select_values("SELECT DISTINCT period_type FROM project_percent_done_snapshots")
assert(values == ["weekly"], "upgrade did not backfill existing rows to weekly: #{values.inspect}")
count = connection.select_value("SELECT COUNT(*) FROM project_percent_done_snapshots").to_i
assert(count == 1, "upgrade changed snapshot row count: #{count}")
puts "upgrade=ok"
'@ | Set-Content -LiteralPath $RubyScript -Encoding UTF8

$env:PLUGIN_PATH = $PluginPath
$env:DATABASE_PATH = $DatabasePath
$env:BUNDLE_GEMFILE = Join-Path $RuntimeRoot "Gemfile"

Push-Location $RuntimeRoot
try {
  & $Ruby $RubyScript
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}
finally {
  Pop-Location
  Remove-Item -LiteralPath $RubyScript -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $DatabasePath -Force -ErrorAction SilentlyContinue
}
