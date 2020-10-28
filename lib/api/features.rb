# frozen_string_literal: true

module API
  class Features < ::API::Base
    before { authenticated_as_admin! }

    helpers do
      def gate_value(params)
        case params[:value]
        when 'true'
          true
        when '0', 'false'
          false
        else
          params[:value].to_i
        end
      end

      def gate_key(params)
        case params[:key]
        when 'percentage_of_actors'
          :percentage_of_actors
        else
          :percentage_of_time
        end
      end

      def gate_targets(params)
        Feature::Target.new(params).targets
      end

      def gate_specified?(params)
        Feature::Target.new(params).gate_specified?
      end
    end

    resource :features do
      desc 'Get a list of all features' do
        success Entities::Feature
      end
      get do
        features = Feature.all

        present features, with: Entities::Feature, current_user: current_user
      end

      desc 'Set the gate value for the given feature' do
        success Entities::Feature
      end
      params do
        requires :value, type: String, desc: '`true` or `false` to enable/disable, an integer for percentage of time'
        optional :key, type: String, desc: '`percentage_of_actors` or the default `percentage_of_time`'
        optional :feature_group, type: String, desc: 'A Feature group name'
        optional :user, type: String, desc: 'A GitLab username'
        optional :group, type: String, desc: "A GitLab group's path, such as 'gitlab-org'"
        optional :project, type: String, desc: 'A projects path, like gitlab-org/gitlab-ce'

        mutually_exclusive :key, :feature_group
        mutually_exclusive :key, :user
        mutually_exclusive :key, :group
        mutually_exclusive :key, :project
      end
      post ':name' do
        validate_feature_flag_name!(params[:name])

        feature = Feature.get(params[:name]) # rubocop:disable Gitlab/AvoidFeatureGet
        targets = gate_targets(params)
        value = gate_value(params)
        key = gate_key(params)

        case value
        when true
          if gate_specified?(params)
            targets.each { |target| feature.enable(target) }
          else
            feature.enable
          end
        when false
          if gate_specified?(params)
            targets.each { |target| feature.disable(target) }
          else
            feature.disable
          end
        else
          if key == :percentage_of_actors
            feature.enable_percentage_of_actors(value)
          else
            feature.enable_percentage_of_time(value)
          end
        end

        present feature, with: Entities::Feature, current_user: current_user
      end

      desc 'Remove the gate value for the given feature'
      delete ':name' do
        Feature.remove(params[:name])

        no_content!
      end
    end

    helpers do
      def validate_feature_flag_name!(name)
        # no-op
      end
    end
  end
end

API::Features.prepend_if_ee('EE::API::Features')
