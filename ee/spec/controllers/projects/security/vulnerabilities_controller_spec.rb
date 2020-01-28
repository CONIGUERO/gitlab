# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::VulnerabilitiesController do
  let_it_be(:group)   { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, namespace: group) }
  let_it_be(:user)    { create(:user) }

  before do
    group.add_developer(user)
  end

  describe 'GET #index' do
    render_views

    def show_vulnerability_list(current_user = user)
      sign_in(current_user)
      get :index, params: { namespace_id: project.namespace, project_id: project }
    end

    context "when we have vulnerabilities" do
      30.times do
        let_it_be(:vulnerability) { create(:vulnerability, project: project) }
        let_it_be(:finding) { create(:vulnerabilities_occurrence, vulnerability: vulnerability) }
      end

      it 'renders the vulnerability list' do
        show_vulnerability_list

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:index)
        expect(response.body).to have_css(".vulnerabilities-list")
      end

      it 'renders the first 20 vulnerabilities' do
        show_vulnerability_list

        expect(response.body).to have_css(".js-vulnerability", count: 20)
      end

      it 'renders the pagination' do
        show_vulnerability_list

        expect(response.body).to have_css(".gl-pagination")
      end
    end

    context "when we have no vulnerabilities" do
      it 'renders the empty state' do
        show_vulnerability_list

        expect(response).to have_gitlab_http_status(200)
        expect(response.body).to have_css('.empty-state')
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(first_class_vulnerabilities: false)
      end

      it 'renders the 404 page' do
        show_vulnerability_list

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
