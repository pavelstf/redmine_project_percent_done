require File.expand_path('../../test_helper', __dir__)
require Rails.root.join('plugins/redmine_project_percent_done/db/migrate/002_add_period_type_to_project_percent_done_snapshots')

class ProjectPercentDone::MigrationPeriodTypeTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def test_down_preserves_real_schema_and_same_date_weekly_monthly_rows
    snapshots = %w[weekly monthly].map do |period|
      ProjectPercentDoneSnapshot.create!(
        :project => test_project, :snapshot_kind => 'official', :period_type => period,
        :period_end => Date.new(2026, 5, 31), :captured_at => Time.current, :project_state => 'active'
      )
    end
    connection = ActiveRecord::Base.connection
    columns = connection.columns(:project_percent_done_snapshots).map(&:name)
    indexes = connection.indexes(:project_percent_done_snapshots).map { |index| [index.name, index.columns, index.unique] }
    assert_raises(ActiveRecord::IrreversibleMigration) { AddPeriodTypeToProjectPercentDoneSnapshots.new.down }
    assert_equal columns, connection.columns(:project_percent_done_snapshots).map(&:name)
    assert_equal indexes, connection.indexes(:project_percent_done_snapshots).map { |index| [index.name, index.columns, index.unique] }
    assert_equal %w[weekly monthly], snapshots.map { |snapshot| snapshot.reload.period_type }
  end
  class FakePeriodTypeMigration < AddPeriodTypeToProjectPercentDoneSnapshots
    attr_reader :operations

    def initialize(columns:, indexes:)
      super()
      @columns = columns.map(&:to_sym)
      @indexes = indexes.map { |index| normalize_index(index) }
      @operations = []
    end

    def column_exists?(_table, column)
      @columns.include?(column.to_sym)
    end

    def add_column(_table, column, _type, **_options)
      @operations << [:add_column, column.to_sym]
      @columns << column.to_sym
    end

    def remove_column(_table, column)
      @operations << [:remove_column, column.to_sym]
      @columns.delete(column.to_sym)
    end

    def execute(sql)
      @operations << [:execute, sql.squish]
    end

    def index_exists?(_table, columns, name:)
      @indexes.include?(normalize_index([columns, name]))
    end

    def add_index(_table, columns, **options)
      @operations << [:add_index, columns.map(&:to_sym), options[:name]]
      @indexes << normalize_index([columns, options[:name]])
    end

    def remove_index(_table, name:)
      @operations << [:remove_index, name]
      @indexes.reject! { |_columns, index_name| index_name == name }
    end

    private

    def normalize_index(index)
      columns, name = index
      [columns.map(&:to_sym), name]
    end
  end

  def test_up_skips_duplicate_period_type_for_fresh_install_schema
    migration = FakePeriodTypeMigration.new(
      :columns => [:period_type],
      :indexes => [[[:project_id, :period_type, :period_end], 'idx_ppd_snapshots_project_period']]
    )

    migration.up

    refute_includes migration.operations, [:add_column, :period_type]
    assert migration.operations.any? { |operation, sql| operation == :execute && sql.include?("SET period_type = 'weekly'") }
    refute migration.operations.any? { |operation, _columns, _name| operation == :add_index }
  end

  def test_up_adds_period_type_and_replaces_old_unique_index_for_upgrade_schema
    migration = FakePeriodTypeMigration.new(
      :columns => [],
      :indexes => [[[:project_id, :period_end], 'idx_ppd_snapshots_project_period']]
    )

    migration.up

    assert_includes migration.operations, [:add_column, :period_type]
    assert_includes migration.operations, [:remove_index, 'idx_ppd_snapshots_project_period']
    assert_includes migration.operations, [:add_index, [:project_id, :period_type, :period_end], 'idx_ppd_snapshots_project_period']
  end

  def test_down_refuses_before_any_schema_operation
    migration = FakePeriodTypeMigration.new(
      :columns => [],
      :indexes => []
    )

    assert_raises(ActiveRecord::IrreversibleMigration) { migration.down }
    assert_empty migration.operations
  end
end
