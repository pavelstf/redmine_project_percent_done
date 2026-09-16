class CreateProjectPercentDoneHistory < ActiveRecord::Migration[6.1]
  def change
    create_table :project_percent_done_collection_runs do |t|
      t.string :source, :null => false
      t.string :status, :null => false
      t.string :snapshot_type
      t.date :target_period_end
      t.datetime :started_at, :null => false
      t.datetime :completed_at
      t.integer :projects_processed, :null => false, :default => 0
      t.integer :projects_succeeded, :null => false, :default => 0
      t.integer :projects_failed, :null => false, :default => 0
      t.integer :snapshots_created, :null => false, :default => 0
      t.integer :snapshots_promoted, :null => false, :default => 0
      t.integer :issue_snapshots_created, :null => false, :default => 0
      t.integer :details_deleted, :null => false, :default => 0
      t.integer :projects_recovered, :null => false, :default => 0
      t.text :errors_json
      t.string :email_status, :null => false, :default => 'not_attempted'
      t.integer :email_recipient_count, :null => false, :default => 0
      t.integer :duration_ms
      t.timestamps :null => false
    end

    add_index :project_percent_done_collection_runs, :started_at,
              :name => 'idx_ppd_runs_started_at'
    add_index :project_percent_done_collection_runs, [:target_period_end, :status],
              :name => 'idx_ppd_runs_period_status'

    create_table :project_percent_done_snapshots do |t|
      t.integer :project_id, :null => false
      t.integer :collection_run_id
      t.integer :officialized_by_run_id
      t.string :snapshot_kind, :null => false
      t.string :period_type, :null => false, :default => 'weekly'
      t.date :period_end
      t.datetime :captured_at, :null => false
      t.string :project_state, :null => false
      t.string :snapshot_source, :null => false, :default => 'direct'
      t.string :timing, :null => false, :default => 'on_time'
      t.integer :deviation_seconds, :null => false, :default => 0
      t.text :project_type_values_json
      t.integer :project_start_custom_field_id
      t.string :project_start_custom_field_name
      t.integer :project_planned_end_custom_field_id
      t.string :project_planned_end_custom_field_name
      t.date :project_start_date
      t.date :project_planned_end_date
      t.string :plan_calendar_mode, :null => false, :default => 'calendar_days_v1'
      t.string :plan_phase
      t.boolean :first_observed_plan, :null => false, :default => false
      t.boolean :start_date_changed, :null => false, :default => false
      t.boolean :planned_end_date_changed, :null => false, :default => false
      t.integer :start_date_change_days
      t.integer :planned_end_date_change_days
      t.integer :planned_duration_days
      t.integer :elapsed_plan_days
      t.decimal :elapsed_plan_percent, :precision => 8, :scale => 4
      t.decimal :schedule_variance_points, :precision => 12, :scale => 6
      t.integer :days_before_start
      t.integer :days_overdue
      t.decimal :spent_hours_total, :precision => 16, :scale => 4
      t.integer :time_entry_count
      t.decimal :hours_before_start, :precision => 16, :scale => 4
      t.decimal :hours_within_plan, :precision => 16, :scale => 4
      t.decimal :hours_after_planned_end, :precision => 16, :scale => 4
      t.decimal :hours_unclassified, :precision => 16, :scale => 4
      t.date :first_time_entry_on
      t.date :last_time_entry_on
      t.boolean :pre_start_activity, :null => false, :default => false
      t.boolean :post_end_activity, :null => false, :default => false
      t.integer :display_percent_done
      t.decimal :raw_percent_done, :precision => 12, :scale => 6
      t.integer :all_project_issue_count
      t.integer :eligible_issue_count
      t.integer :included_issue_count
      t.integer :not_included_issue_count
      t.integer :estimated_issue_count
      t.integer :unestimated_issue_count
      t.integer :estimated_eligible_issue_count
      t.integer :unestimated_eligible_issue_count
      t.integer :excluded_parent_issue_count
      t.integer :ignored_unestimated_issue_count
      t.decimal :known_estimated_hours, :precision => 16, :scale => 4
      t.decimal :total_weight, :precision => 16, :scale => 4
      t.decimal :imputed_weight, :precision => 16, :scale => 4
      t.decimal :estimate_coverage_percent, :precision => 8, :scale => 4
      t.text :warnings_json
      t.text :calculation_settings_json
      t.string :algorithm_version
      t.string :plugin_version
      t.string :rounding_mode
      t.datetime :details_purged_at
      t.timestamps :null => false
    end

    add_index :project_percent_done_snapshots, [:project_id, :period_type, :period_end],
              :unique => true, :name => 'idx_ppd_snapshots_project_period'
    add_index :project_percent_done_snapshots, [:project_id, :snapshot_kind, :captured_at],
              :name => 'idx_ppd_snapshots_project_kind_time'
    add_index :project_percent_done_snapshots, :collection_run_id,
              :name => 'idx_ppd_snapshots_run'
    add_foreign_key :project_percent_done_snapshots, :projects,
                    :column => :project_id, :on_delete => :cascade
    add_foreign_key :project_percent_done_snapshots,
                    :project_percent_done_collection_runs,
                    :column => :collection_run_id, :on_delete => :nullify,
                    :name => 'fk_ppd_snapshots_capture_run'
    add_foreign_key :project_percent_done_snapshots,
                    :project_percent_done_collection_runs,
                    :column => :officialized_by_run_id, :on_delete => :nullify,
                    :name => 'fk_ppd_snapshots_official_run'

    create_table :project_percent_done_issue_snapshots do |t|
      t.integer :project_percent_done_snapshot_id, :null => false
      t.integer :issue_id, :null => false
      t.string :subject, :null => false
      t.integer :status_id
      t.string :status_name
      t.decimal :original_done_ratio, :precision => 8, :scale => 4
      t.decimal :effective_done_ratio, :precision => 8, :scale => 4
      t.decimal :estimated_hours, :precision => 16, :scale => 4
      t.decimal :applied_weight, :precision => 16, :scale => 4
      t.decimal :weighted_value, :precision => 16, :scale => 4
      t.boolean :included, :null => false, :default => false
      t.string :exclusion_reason
      t.text :notes_json
      t.timestamps :null => false
    end

    add_index :project_percent_done_issue_snapshots,
              [:project_percent_done_snapshot_id, :issue_id],
              :unique => true, :name => 'idx_ppd_issue_snapshots_parent_issue'
    add_index :project_percent_done_issue_snapshots, :issue_id,
              :name => 'idx_ppd_issue_snapshots_issue'
    add_foreign_key :project_percent_done_issue_snapshots,
                    :project_percent_done_snapshots,
                    :on_delete => :cascade,
                    :name => 'fk_ppd_issue_snapshots_parent'
  end
end
