class AddPeriodTypeToProjectPercentDoneSnapshots < ActiveRecord::Migration[6.1]
  def up
    unless column_exists?(:project_percent_done_snapshots, :period_type)
      add_column :project_percent_done_snapshots, :period_type, :string,
                 :null => false, :default => 'weekly'
    end

    execute <<~SQL.squish
      UPDATE project_percent_done_snapshots
         SET period_type = 'weekly'
       WHERE period_type IS NULL OR period_type = ''
    SQL

    if index_exists?(:project_percent_done_snapshots, [:project_id, :period_end],
                     :name => 'idx_ppd_snapshots_project_period')
      remove_index :project_percent_done_snapshots,
                   :name => 'idx_ppd_snapshots_project_period'
    end

    unless index_exists?(:project_percent_done_snapshots,
                         [:project_id, :period_type, :period_end],
                         :name => 'idx_ppd_snapshots_project_period')
      add_index :project_percent_done_snapshots,
                [:project_id, :period_type, :period_end],
                :unique => true,
                :name => 'idx_ppd_snapshots_project_period'
    end
  end

  def down
    if index_exists?(:project_percent_done_snapshots,
                     [:project_id, :period_type, :period_end],
                     :name => 'idx_ppd_snapshots_project_period')
      remove_index :project_percent_done_snapshots,
                   :name => 'idx_ppd_snapshots_project_period'
    end

    unless index_exists?(:project_percent_done_snapshots, [:project_id, :period_end],
                         :name => 'idx_ppd_snapshots_project_period')
      add_index :project_percent_done_snapshots,
                [:project_id, :period_end],
                :unique => true,
                :name => 'idx_ppd_snapshots_project_period'
    end

    remove_column :project_percent_done_snapshots, :period_type if column_exists?(:project_percent_done_snapshots, :period_type)
  end
end
