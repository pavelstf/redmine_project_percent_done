require File.expand_path('../../test_helper', __dir__)
require 'yaml'

class ProjectPercentDone::QaRegressionsTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def setup
    Setting.issue_done_ratio = 'issue_field'
  end

  def test_fractional_estimates_round_exact_integer_down_without_float_artifact
    create_test_issue(:estimated_hours => 0.1, :done_ratio => 70)
    create_test_issue(:estimated_hours => 0.2, :done_ratio => 70)
    assert_progress_for_modes(70.0, 'floor' => 70, 'ceil' => 70, 'nearest_integer' => 70)
  end

  def test_fractional_estimates_round_exact_integer_up_without_float_artifact
    create_test_issue(:estimated_hours => 0.2, :done_ratio => 10)
    create_test_issue(:estimated_hours => 0.05, :done_ratio => 50)
    assert_progress_for_modes(18.0, 'floor' => 18, 'ceil' => 18, 'nearest_integer' => 18)
  end

  def test_decimal_average_imputation_preserves_integer_progress
    create_test_issue(:estimated_hours => 0.1, :done_ratio => 70)
    create_test_issue(:estimated_hours => 0.2, :done_ratio => 70)
    create_test_issue(:estimated_hours => nil, :done_ratio => 70)
    assert_progress_for_modes(70.0, 'floor' => 70, 'ceil' => 70)
  end

  def test_true_values_near_integer_boundary_are_not_snapped
    [[0.999999999, 0, 1], [1.000000001, 1, 2]].each do |raw, floor, ceil|
      calculator = ProjectPercentDone::ProjectProgressCalculator.new(test_project)
      with_project_percent_done_settings('rounding_mode' => 'floor') do
        assert_equal floor, calculator.send(:rounded, Rational(raw.to_s))
      end
      with_project_percent_done_settings('rounding_mode' => 'ceil') do
        assert_equal ceil, calculator.send(:rounded, Rational(raw.to_s))
      end
    end
  end

  def test_cross_project_parent_is_excluded_and_evidence_describes_global_children
    other = Project.create!(:name => 'QA other', :identifier => "qa-other-#{SecureRandom.hex(4)}")
    with_settings(:cross_project_subtasks => 'system') do
      parent = create_test_issue(:estimated_hours => 8, :done_ratio => 90)
      foreign_child = create_test_issue(:project => other, :parent_issue_id => parent.id,
                                        :estimated_hours => 8, :done_ratio => 90)
      direct_leaf = create_test_issue(:estimated_hours => 2, :done_ratio => 50)
      with_project_percent_done_settings({}) do
        default = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project)
        payload = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project, :include_evidence => true).to_h
        assert_equal 50.0, default.raw_percent_done
        assert_equal default.raw_percent_done, payload[:raw_percent_done]
        assert_equal 1, payload[:excluded_parent_issue_count]
        assert_equal 1, payload[:eligible_issue_count]
        assert_equal [parent.id, direct_leaf.id].sort, payload[:issue_evidence].map { |row| row[:issue_id] }.sort
        refute_includes payload[:issue_evidence].map { |row| row[:issue_id] }, foreign_child.id
        row = payload[:issue_evidence].find { |item| item[:issue_id] == parent.id }
        assert_equal false, row[:included_in_progress]
        assert_equal true, row[:is_parent]
        assert_equal 1, row[:children_count]
        assert_equal 'parent_issue_excluded', row[:exclusion_reason]
        assert_equal '1.2', payload[:provider_metadata][:algorithm_version]
      end
    end
  end

  def test_locale_roots_are_strings_matching_filenames_and_norwegian_resolves
    Dir[File.expand_path('../../../config/locales/*.yml', __dir__)].each do |file|
      assert_equal [File.basename(file, '.yml')], YAML.load_file(file).keys, file
    end
    I18n.backend.load_translations(File.expand_path('../../../config/locales/no.yml', __dir__))
    assert_equal 'Project % done', I18n.t(:label_project_percent_done, :locale => :no)
    assert_equal I18n.t(:text_project_percent_done_history_test_email_failed, :locale => :en),
                 I18n.t(:text_project_percent_done_history_test_email_failed, :locale => :no)
  end

  def test_null_nested_set_coordinates_are_excluded_without_breaking_calculation_or_api
    invalid = 3.times.map { create_test_issue(:estimated_hours => 100, :done_ratio => 100) }
    leaf = create_test_issue(:estimated_hours => 2, :done_ratio => 70)
    [[nil, nil], [nil, 2], [1, nil]].zip(invalid).each do |bounds, issue|
      Issue.where(:id => issue.id).update_all(:lft => bounds[0], :rgt => bounds[1])
    end
    with_project_percent_done_settings({}) do
      [:summary, :details].each do |mode|
        result = ProjectPercentDone::ProjectProgressCalculator.new(test_project, :mode => mode).call
        assert_equal 70, result.percent_done
        assert_equal 70.0, result.raw_percent_done
        assert_equal [leaf.id], result.included_issue_ids
        assert_equal invalid.map(&:id).sort, result.not_included_issue_ids.sort
        assert_equal 1, result.eligible_issue_count
      end
      default = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project)
      evidence = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project, :include_evidence => true)
      assert_equal 70, default.display_percent_done
      assert_equal default.raw_percent_done, evidence.raw_percent_done
      assert_equal invalid.map(&:id).sort,
                   evidence.issue_evidence.reject { |row| row[:included_in_progress] }.map { |row| row[:issue_id] }.sort
      assert_equal 4, evidence.issue_evidence.size
      invalid.each do |issue|
        refute issue.reload.lft && issue.rgt, 'Calculation must not repair or rewrite corrupt source data'
      end
    end
  end

  def test_project_with_only_incomplete_hierarchy_reports_unavailable_progress
    issue = create_test_issue(:estimated_hours => 100, :done_ratio => 100)
    Issue.where(:id => issue.id).update_all(:lft => nil, :rgt => nil)
    with_project_percent_done_settings({}) do
      [:summary, :details].each do |mode|
        result = ProjectPercentDone::ProjectProgressCalculator.new(test_project, :mode => mode).call
        assert_equal 0, result.percent_done
        assert_equal [:no_eligible_issues], result.warnings
        assert_equal [], result.included_issue_ids
      end
      evidence = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project, :include_evidence => true)
      assert_equal false, evidence.progress_available
      assert_equal :no_eligible_issues, evidence.unavailable_reason
      assert_nil evidence.raw_percent_done
      assert_equal false, evidence.issue_evidence.first[:included_in_progress]
    end
  end

  private

  def assert_progress_for_modes(raw, modes)
    modes.each do |mode, expected|
      with_project_percent_done_settings('rounding_mode' => mode) do
        [:summary, :details].each do |detail|
          result = ProjectPercentDone::ProjectProgressCalculator.new(test_project, :mode => detail).call
          assert_equal expected, result.percent_done
          assert_equal raw, result.raw_percent_done
          assert_kind_of Float, result.raw_percent_done
          assert_kind_of Float, result.total_weight
          assert_kind_of Array, result.non_progress_status_ids
          if detail == :details
            assert_in_delta result.raw_percent_done,
                            result.included_rows.sum(&:weighted_value) / result.total_weight * 100, 1e-10
          end
        end
        evidence = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project, :include_evidence => true)
        assert_equal expected, evidence.display_percent_done
        assert_equal raw, evidence.raw_percent_done
      end
    end
  end

end
