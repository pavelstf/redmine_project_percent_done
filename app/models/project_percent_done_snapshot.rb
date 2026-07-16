class ProjectPercentDoneSnapshot < ActiveRecord::Base
  self.table_name = 'project_percent_done_snapshots'

  belongs_to :project
  belongs_to :collection_run,
             :class_name => 'ProjectPercentDoneCollectionRun',
             :optional => true
  belongs_to :officialized_by_run,
             :class_name => 'ProjectPercentDoneCollectionRun',
             :optional => true
  has_many :issue_snapshots,
           :class_name => 'ProjectPercentDoneIssueSnapshot',
           :dependent => :delete_all

  scope :official, lambda { where(:snapshot_kind => 'official') }
  scope :operational, lambda { where(:snapshot_kind => 'operational') }
  scope :latest_first, lambda { order(:period_end => :desc, :captured_at => :desc) }

  validates :project_id, :snapshot_kind, :captured_at, :project_state, :presence => true
  validates :snapshot_kind, :inclusion => { :in => %w[official operational] }
  validates :project_state,
            :inclusion => { :in => %w[active closed archived out_of_scope] }
  validates :plan_phase,
            :inclusion => {
              :in => %w[
                insufficient_date_data planned_not_started pre_start_activity
                within_planned_period overdue_active after_planned_end
              ],
              :allow_nil => true
            }
  validates :period_end, :presence => true, :if => :official?

  def official?
    snapshot_kind == 'official'
  end

  def operational?
    snapshot_kind == 'operational'
  end

  def active?
    project_state == 'active'
  end

  def observed_plan_changed?
    start_date_changed? || planned_end_date_changed?
  end

  def warnings
    parse_json_array(warnings_json)
  end

  def warnings=(value)
    self.warnings_json = Array(value).map(&:to_s).to_json
  end

  def project_type_values
    parse_json_array(project_type_values_json)
  end

  def project_type_values=(value)
    self.project_type_values_json = Array(value).map(&:to_s).to_json
  end

  def calculation_settings
    parsed = JSON.parse(calculation_settings_json.presence || '{}')
    parsed.is_a?(Hash) ? parsed : {}
  rescue JSON::ParserError
    {}
  end

  def calculation_settings=(value)
    self.calculation_settings_json = value.to_h.stringify_keys.to_json
  end

  private

  def parse_json_array(value)
    parsed = JSON.parse(value.presence || '[]')
    parsed.is_a?(Array) ? parsed : []
  rescue JSON::ParserError
    []
  end
end
