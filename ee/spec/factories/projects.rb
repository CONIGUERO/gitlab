# frozen_string_literal: true

FactoryBot.modify do
  factory :project do
    transient do
      last_update_at { nil }
      last_successful_update_at { nil }
      retry_count { 0 }
    end

    after(:create) do |project, evaluator|
      import_state = project.import_state
      if import_state
        import_state.last_successful_update_at = evaluator.last_successful_update_at
        import_state.retry_count = evaluator.retry_count

        case import_state.status.to_sym
        when :scheduled
          import_state.last_update_scheduled_at = Time.current
        when :started
          import_state.last_update_started_at = Time.current
        when :finished
          timestamp = evaluator.last_update_at || Time.current
          import_state.last_update_at = timestamp
          import_state.last_successful_update_at = timestamp
        when :failed
          import_state.last_update_at = evaluator.last_update_at || Time.current
        end
        import_state.save!
      end
    end

    trait :import_none do
      import_status { :none }
    end

    trait :import_hard_failed do
      import_status { :failed }
      last_update_at { Time.current - 1.minute }
      retry_count { Gitlab::Mirror::MAX_RETRY + 1 }
    end

    trait :disabled_mirror do
      mirror { false }
      import_url { generate(:url) }
      mirror_user_id { creator_id }
    end

    trait :mirror do
      mirror { true }
      import_url { generate(:url) }
      mirror_user_id { creator_id }
    end

    trait :random_last_repository_updated_at do
      last_repository_updated_at { rand(1.year).seconds.ago }
    end

    trait :jira_dvcs_cloud do
      before(:create) do |project|
        create(:project_feature_usage, :dvcs_cloud, project: project)
      end
    end

    trait :jira_dvcs_server do
      before(:create) do |project|
        create(:project_feature_usage, :dvcs_server, project: project)
      end
    end

    trait :github_imported do
      import_type { 'github' }
    end

    trait :with_vulnerability do
      after(:create) do |project|
        create(:vulnerability, :detected, project: project)
      end
    end

    trait :with_vulnerabilities do
      after(:create) do |project|
        create_list(:vulnerability, 2, :detected, project: project)
      end
    end

    trait :with_compliance_framework do
      association :compliance_framework_setting, factory: :compliance_framework_project_setting
    end

    trait :with_sox_compliance_framework do
      association :compliance_framework_setting, factory: :compliance_framework_project_setting, framework: 'sox'
    end
  end
end
