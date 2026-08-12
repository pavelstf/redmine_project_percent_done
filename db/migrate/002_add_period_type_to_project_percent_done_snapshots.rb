class AddPeriodTypeToProjectPercentDoneSnapshots < ActiveRecord::Migration[6.1]
  def up
    add_column :project_percent_done_snapshots, :period_type, :string,
               :null => false, :default => 'weekly'

    if index_exists?(:project_percent_done_snapshots, [:project_id, :period_end],
                     :name => 'idx_ppd_snapshots_project_period')
      remove_index :project_percent_done_snapshots,
                   :name => 'idx_ppd_snapshots_project_period'
    end

    add_index :project_percent_done_snapshots,
              [:project_id, :period_type, :period_end],
              :unique => true,
              :name => 'idx_ppd_snapshots_project_period'
  end

  def down
    if index_exists?(:project_percent_done_snapshots,
                     [:project_id, :period_type, :period_end],
                     :name => 'idx_ppd_snapshots_project_period')
      remove_index :project_percent_done_snapshots,
                   :name => 'idx_ppd_snapshots_project_period'
    end

    add_index :project_percent_done_snapshots,
              [:project_id, :period_end],
              :unique => true,
              :name => 'idx_ppd_snapshots_project_period'

    remove_column :project_percent_done_snapshots, :period_type
  end
end
