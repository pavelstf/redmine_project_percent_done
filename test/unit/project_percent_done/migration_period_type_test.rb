require File.expand_path('../../test_helper', __dir__)
require Rails.root.join('plugins/redmine_project_percent_done/db/migrate/002_add_period_type_to_project_percent_done_snapshots')

class ProjectPercentDone::MigrationPeriodTypeTest < ActiveSupport::TestCase
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

  def test_down_is_safe_when_period_type_was_already_removed
    migration = FakePeriodTypeMigration.new(
      :columns => [],
      :indexes => []
    )

    migration.down

    refute_includes migration.operations, [:remove_column, :period_type]
    assert_includes migration.operations, [:add_index, [:project_id, :period_end], 'idx_ppd_snapshots_project_period']
  end
end
