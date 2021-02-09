# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).apiFuzzingCiConfiguration' do
  include GraphqlHelpers
  include StubRequests

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let_it_be(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          apiFuzzingCiConfiguration {
            scanModes
            scanProfiles {
              name
              description
              yaml
            }
          }
        }
      }
    )
  end

  let_it_be(:profiles_yaml) do
    YAML.dump(
      Profiles: [
        { Name: 'Quick-10' }
      ]
    )
  end

  before do
    project.add_developer(user)

    stub_full_request(
      ::Security::ApiFuzzing::CiConfiguration::PROFILES_DEFINITION_FILE
    ).to_return(body: profiles_yaml)
  end

  context 'when the api_fuzzing_configuration_ui feature flag is enabled' do
    before do
      stub_feature_flags(api_fuzzing_configuration_ui: true)
    end

    context 'when the user can read vulnerabilities for the project' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      it 'returns scan modes and scan profiles' do
        post_graphql(query, current_user: user)

        expect(response).to have_gitlab_http_status(:ok)

        fuzzing_config = graphql_data.dig('project', 'apiFuzzingCiConfiguration')
        modes = fuzzing_config['scanModes']
        profiles = fuzzing_config['scanProfiles']
        expect(modes).to contain_exactly('HAR', 'OPENAPI')
        expect(profiles).to contain_exactly({
          'name' => 'Quick-10',
          'description' => 'Fuzzing 10 times per parameter',
          'yaml' => "---\nName: Quick-10\n"
        })
      end
    end

    context 'when the user cannot read vulnerabilities for the project' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'returns null' do
        post_graphql(query, current_user: user)

        expect(response).to have_gitlab_http_status(:ok)

        fuzzing_config = graphql_data.dig('project', 'apiFuzzingCiConfiguration')
        expect(fuzzing_config).to be_nil
      end
    end
  end

  context 'when the api_fuzzing_configuration_ui feature flag is disabled' do
    before do
      stub_feature_flags(api_fuzzing_configuration_ui: false)
    end

    it 'errors' do
      post_graphql(query, current_user: user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(graphql_errors.first['message']).to eq(
        "Field 'apiFuzzingCiConfiguration' doesn't exist on type 'Project'"
      )
    end
  end
end