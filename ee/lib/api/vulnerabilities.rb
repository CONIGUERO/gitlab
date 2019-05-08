# frozen_string_literal: true

module API
  class Vulnerabilities < Grape::API
    include PaginationParams

    helpers do
      def vulnerability_occurrences_by(params)
        pipeline = params[:project].latest_pipeline_with_security_reports

        return [] unless pipeline

        Security::PipelineVulnerabilitiesFinder.new(pipeline: pipeline, params: params).execute
      end
    end

    before do
      authenticate!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of project vulnerabilities' do
        success ::Vulnerabilities::OccurrenceEntity
      end

      params do
        optional :report_type, type: Array[String], desc: 'The type of report vulnerability belongs to', default: ::Vulnerabilities::Occurrence.report_types.keys
        optional :scope, type: String, desc: 'Return vulnerabilities for the given scope: `dismissed` or `all`', default: 'dismissed', values: %w[all dismissed]
        optional :severity,
                 type: Array[String],
                 desc: 'Returns issues belonging to specified severity level: `undefined`, `info`, `unknown`, `low`, `medium`, `high`, or `critical`. Defaults to all',
                 default: ::Vulnerabilities::Occurrence.severities.keys
        optional :confidence,
                 type: Array[String],
                 desc: 'Returns vulnerabilities belonging to specified confidence level: `undefined`, `ignore`, `unknown`, `experimental`, `low`, `medium`, `high`, or `confirmed`. Defaults to all',
                 default: ::Vulnerabilities::Occurrence.confidences.keys

        use :pagination
      end

      get ':id/vulnerabilities' do
        project = Project.find(params[:id])

        not_found!('Project') unless project && can?(current_user, :read_project_security_dashboard, project)

        vulnerability_occurrences = Kaminari.paginate_array(
          vulnerability_occurrences_by(declared_params.merge(project: project))
        )

        present paginate(vulnerability_occurrences),
          with: ::Vulnerabilities::OccurrenceEntity,
          request: GrapeRequestProxy.new(request, current_user)
      end
    end
  end
end
