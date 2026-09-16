class ProjectPercentDoneIssueSnapshot < ActiveRecord::Base
  self.table_name = 'project_percent_done_issue_snapshots'

  belongs_to :snapshot,
             :class_name => 'ProjectPercentDoneSnapshot',
             :foreign_key => 'project_percent_done_snapshot_id'

  validates :project_percent_done_snapshot_id, :issue_id, :subject, :presence => true

  def notes
    parsed = JSON.parse(notes_json.presence || '[]')
    parsed.is_a?(Array) ? parsed : []
  rescue JSON::ParserError
    []
  end

  def notes=(value)
    self.notes_json = Array(value).map(&:to_s).to_json
  end
end
