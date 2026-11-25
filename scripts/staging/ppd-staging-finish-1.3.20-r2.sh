clear
# Self-contained asset completion and read-only registry/API validation.
set -Eeo pipefail
PHASE='Ruby activation'
trap 'rc=$?; printf "ERROR: finish phase=%s line=%s exit=%s\n" "$PHASE" "$LINENO" "$rc" >&2; exit "$rc"' ERR
umask 077
ROOT=/home/gcrbgcaa/redminestaging
PLUGIN=redmine_project_percent_done
if source /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/activate; then
  echo 'VENV_ACTIVATED'
else
  rc=$?; echo "Activation failed: $rc" >&2; exit "$rc"
fi
set -u
cd "$ROOT"
test "$(pwd -P)" = "$ROOT"
test "$(id -un)" = gcrbgcaa
WORK="$(mktemp -d /tmp/ppd-staging-finish.XXXXXXXX)"
trap 'rc=$?; if [ "$rc" -ne 0 ]; then echo "Finish check stopped; diagnostics: $WORK" >&2; fi' EXIT
PHASE='asset backup'
ASSETS=()
for path in "public/plugin_assets/$PLUGIN" "public/assets/plugin_assets/$PLUGIN"; do
  case "$(realpath -m "$ROOT/$path")" in "$ROOT"/*) ;; *) exit 1;; esac
  test ! -L "$ROOT/$path"
  if [ -d "$ROOT/$path" ]; then ASSETS+=("$path"); fi
done
test "${#ASSETS[@]}" -gt 0
BACKUP="$ROOT/plugins/${PLUGIN}-staging-assets-finish-backup-$(date -u +%Y%m%dT%H%M%SZ)-$$.tar.gz"
tar -czf "$BACKUP" -C "$ROOT" "${ASSETS[@]}"
tar -tzf "$BACKUP" >/dev/null
echo "Additional assets backup: $BACKUP"
cat > "$WORK/check.rb" <<'PPD_FINISH_RUBY'
require 'json'
require 'digest'
require 'fileutils'

# ASSET_REFRESH_BEGIN
module PpdStagingAssets
  def self.refresh(root)
    source = File.join(root, 'plugins/redmine_project_percent_done/assets')
    files = Dir.glob(File.join(source, '**', '*')).select { |path| File.file?(path) }
    raise 'Source assets missing' if files.empty?
    count = 0
    files.each do |file|
      relative = file.delete_prefix(source + '/')
      ['public/plugin_assets/redmine_project_percent_done',
       'public/assets/plugin_assets/redmine_project_percent_done'].each_with_index do |base, index|
        base_path = File.join(root, base)
        next if index == 1 && !File.directory?(base_path)
        destination = File.join(base_path, relative)
        FileUtils.mkdir_p(File.dirname(destination))
        real_directory = File.realpath(File.dirname(destination))
        raise 'Asset directory escapes staging root' unless real_directory.start_with?(File.realpath(root) + '/')
        raise 'Unexpected asset symlink' if File.symlink?(destination)
        FileUtils.cp(file, destination, :preserve => true)
        expected = Digest::SHA256.file(file).hexdigest
        raise 'Asset copy mismatch' unless Digest::SHA256.file(destination).hexdigest == expected
        count += 1
        next unless File.extname(file) == '.css' && index == 1
        stem = File.basename(file, '.css')
        Dir.glob(File.join(File.dirname(destination), stem + '-*.css')).each do |compiled|
          raise 'Unexpected compiled asset symlink' if File.symlink?(compiled)
          FileUtils.cp(file, compiled, :preserve => true)
          raise 'Compiled asset mismatch' unless Digest::SHA256.file(compiled).hexdigest == expected
          count += 1
        end
      end
    end
    count
  end
end
# ASSET_REFRESH_END

root = '/home/gcrbgcaa/redminestaging'
abort 'Wrong Rails root/environment' unless Rails.root.realpath.to_s == root && Rails.env.production?
plugin = Redmine::Plugin.find(:redmine_project_percent_done)
abort 'Wrong PPD version' unless plugin.version.to_s == '1.3.20'
api = ProjectPercentDone::PublicApi::V1
abort 'Wrong algorithm/contract' unless api.capabilities.algorithm_version == '1.2' && api.capabilities.contract_version == '1.0'
manifest = JSON.parse(File.read(File.join(root, 'plugins/redmine_project_percent_done/QA_MANIFEST.json')))
abort 'Wrong QA commit' unless manifest['source_commit'] == 'f763c1723d9e586261c5beff9bbd19f1e7270b80'
manifest.fetch('files').each do |name, hash|
  abort 'Unsafe manifest path' unless name.start_with?('redmine_project_percent_done/') && !name.split('/').include?('..')
  abort "Runtime hash mismatch: #{name}" unless Digest::SHA256.file(File.join(root, 'plugins', name)).hexdigest.upcase == hash
end
puts "ASSETS_OK verified_copies=#{PpdStagingAssets.refresh(root)}"
Redmine::Plugin.all.select { |entry| entry.id.to_s.match?(/budget|progress_history|percent_done/) }.each do |entry|
  puts "REGISTERED #{entry.id}=#{entry.version}"
end
pb = begin
  Redmine::Plugin.find(:redmine_project_budget)
rescue Redmine::PluginNotFound
  nil
end
puts "PB_REGISTERED=#{!pb.nil?}"
if pb
  abort 'PB provider missing/incompatible' unless defined?(ProjectBudget::ProgressProvider) && ProjectBudget::ProgressProvider.new.compatible?
  puts "PB_UI_PROGRESS_ENABLED=#{(Setting.plugin_redmine_project_budget || {})['progress_enabled'].to_s == '1'}"
end
[8, 9, 10, 19].each do |id|
  project = Project.find_by(:id => id)
  next unless project
  result = api.calculate(:project => project)
  if pb
    progress = ProjectBudget::ProgressProvider.new.percent(project)
    expected = result.raw_percent_done
    abort "PB mismatch on project #{id}" unless (progress.nil? && expected.nil?) ||
      (!progress.nil? && !expected.nil? && (progress.to_f - expected).abs < 1e-9)
  end
  puts "PROJECT #{id}: available=#{result.progress_available} raw=#{result.raw_percent_done.inspect} display=#{result.display_percent_done.inspect} PB_MATCH=#{!pb.nil?}"
end
puts 'STAGING_FINISH_OK PPD=1.3.20 algorithm=1.2 runtime_hashes=true assets=true'
PPD_FINISH_RUBY
PHASE='asset completion and registry/API verification'
RAILS_ENV=production bundle exec rails runner "$WORK/check.rb" | tee "$WORK/result.log"
grep -Fxq 'STAGING_FINISH_OK PPD=1.3.20 algorithm=1.2 runtime_hashes=true assets=true' "$WORK/result.log"
touch "$ROOT/tmp/restart.txt"
case "$WORK" in /tmp/ppd-staging-finish.*) rm -rf -- "$WORK";; *) exit 1;; esac
trap - ERR EXIT
echo 'SUCCESS: PPD 1.3.20 r2 staging assets completed and registry/API rechecked'
