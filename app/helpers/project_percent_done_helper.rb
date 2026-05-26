module ProjectPercentDoneHelper
  def project_percent_done_result(project)
    ProjectPercentDone::ProjectProgressCalculator.new(project).call
  end

  def project_percent_done_label(result)
    "#{result.percent_done}%"
  end

  def project_percent_done_visible_rows(rows)
    rows.select { |row| row.issue.visible? }
  end

  def project_percent_done_hidden_row_count(rows)
    rows.size - project_percent_done_visible_rows(rows).size
  end

  def project_percent_done_visible_issue_ids(issue_ids)
    return [] if issue_ids.blank?

    Issue.visible.where(:id => issue_ids).pluck(:id)
  end

  def project_percent_done_issues_filter_url(project, issue_ids)
    visible_issue_ids = project_percent_done_visible_issue_ids(issue_ids)
    return nil if visible_issue_ids.empty?

    url_for(
      :controller => 'issues',
      :action => 'index',
      :project_id => project.identifier,
      :set_filter => 1,
      :f => ['issue_id'],
      :op => { 'issue_id' => '=' },
      :v => { 'issue_id' => [visible_issue_ids.join(',')] }
    )
  end

  def project_percent_done_breakdown_note_label(note)
    l(:"label_project_percent_done_note_#{note}")
  end

  def project_percent_done_breakdown_reason_label(reason)
    l(:"label_project_percent_done_reason_#{reason}")
  end
end
