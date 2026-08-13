class ProjectPercentDoneCollectionRun < ActiveRecord::Base
  self.table_name = 'project_percent_done_collection_runs'

  has_many :snapshots,
           :class_name => 'ProjectPercentDoneSnapshot',
           :foreign_key => 'collection_run_id',
           :dependent => :nullify

  scope :latest_first, lambda { order(:started_at => :desc, :id => :desc) }

  validates :source, :status, :started_at, :presence => true

  def errors_list
    parse_json_array(errors_json)
  end

  def errors_list=(value)
    self.errors_json = Array(value).to_json
  end

  def successful?
    status == 'successful'
  end

  def terminal?
    completed_at.present?
  end

  private

  def parse_json_array(value)
    parsed = JSON.parse(value.presence || '[]')
    parsed.is_a?(Array) ? parsed : []
  rescue JSON::ParserError
    []
  end
end
