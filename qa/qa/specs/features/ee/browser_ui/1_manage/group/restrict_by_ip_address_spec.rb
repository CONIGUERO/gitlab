# frozen_string_literal: true
require 'securerandom'

module QA
  context 'Manage' do
    describe 'Group access', :requires_admin, :skip_live_env do
      include Runtime::IPAddress

      before(:all) do
        @sandbox_group = Resource::Sandbox.fabricate! do |sandbox_group|
          sandbox_group.path = "gitlab-qa-ip-restricted-sandbox-group-#{SecureRandom.hex(8)}"
        end

        @user = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)

        @group = Resource::Group.fabricate_via_api! do |group|
          group.path = "ip-address-restricted-group-#{SecureRandom.hex(8)}"
          group.sandbox = @sandbox_group
        end

        enable_plan_on_group(@sandbox_group.path, "Gold") if Runtime::Env.dot_com?
      end

      after(:all) do
        @sandbox_group.remove_via_api!

        page.visit Runtime::Scenario.gitlab_address
        Page::Main::Menu.perform(&:sign_out_if_signed_in)
      end

      before do
        page.visit Runtime::Scenario.gitlab_address

        set_ip_address_restriction_to(ip_address)
      end

      context 'when restricted by another ip address' do
        let(:ip_address) { get_next_ip_address(fetch_current_ip_address) }

        context 'via the UI' do
          it 'denies access' do
            Flow::Login.sign_in(as: @user)

            @group.sandbox.visit!
            expect(page).to have_text('Page Not Found')
            page.go_back

            @group.visit!
            expect(page).to have_text('Page Not Found')
            page.go_back
          end
        end

        context 'via the API' do
          before do
            @api_client ||= Runtime::API::Client.new(:gitlab, user: @user)
          end

          it 'denies access' do
            request = create_request("/groups/#{@sandbox_group.id}")
            response = get request.url
            expect(response.code).to eq(404)

            request = create_request("/groups/#{@group.id}")
            response = get request.url
            expect(response.code).to eq(404)
          end
        end

        # Note: If you run this test against GDK make sure you've enabled sshd
        # See: https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/run_qa_against_gdk.md
        context 'via the SSH' do
          let(:key) { Resource::SSHKey.fabricate_via_api! }

          it 'denies access' do
            Flow::Login.sign_in

            expect { push_a_project_with_ssh_key(key) }.to raise_error(QA::Git::Repository::RepositoryCommandError, /fatal: Could not read from remote repository/)
          end
        end
      end

      context 'when restricted by user\'s ip address' do
        let(:ip_address) { fetch_current_ip_address }

        context 'via the UI' do
          it 'allows access' do
            Flow::Login.sign_in(as: @user)

            @group.sandbox.visit!
            expect(page).to have_text(@group.sandbox.path)

            @group.visit!
            expect(page).to have_text(@group.path)
          end
        end

        context 'via the API' do
          before do
            @api_client ||= Runtime::API::Client.new(:gitlab, user: @user)
          end

          it 'allows access' do
            request = create_request("/groups/#{@sandbox_group.id}")
            response = get request.url
            expect(response.code).to eq(200)

            request = create_request("/groups/#{@group.id}")
            response = get request.url
            expect(response.code).to eq(200)
          end
        end

        # Note: If you run this test against GDK make sure you've enabled sshd
        # See: https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/run_qa_against_gdk.md
        context 'via the SSH' do
          let(:key) { Resource::SSHKey.fabricate_via_api! }

          it 'allows access' do
            Flow::Login.sign_in

            expect { push_a_project_with_ssh_key(key) }.not_to raise_error
          end
        end
      end

      private

      def push_a_project_with_ssh_key(key)
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.group = @sandbox_group
          push.ssh_key = key
          push.file_name = 'README.md'
          push.file_content = '# Test Use SSH Key'
          push.commit_message = 'Add README.md'
        end
      end

      def set_ip_address_restriction_to(ip_address)
        Flow::Login.while_signed_in_as_admin do
          @group.sandbox.visit!

          Page::Group::Menu.perform(&:click_group_general_settings_item)

          Page::Group::Settings::General.perform do |settings|
            settings.set_ip_address_restriction(ip_address)
          end
        end
      end

      def get_next_ip_address(current_ip_address)
        current_last_part = current_ip_address.split(".").pop.to_i

        updated_last_part = current_last_part < 255 ? current_last_part + 1 : 1

        current_ip_address.split(".")[0...-1].push(updated_last_part).join(".")
      end

      def enable_plan_on_group(group, plan)
        Flow::Login.while_signed_in_as_admin do
          Page::Main::Menu.perform(&:go_to_admin_area)
          Page::Admin::Menu.perform(&:go_to_groups_overview)

          Page::Admin::Overview::Groups::Index.perform do |index|
            index.search_group(group)
            index.click_group(group)
          end

          Page::Admin::Overview::Groups::Show.perform(&:click_edit_group_link)

          Page::Admin::Overview::Groups::Edit.perform do |edit|
            edit.select_plan(plan)
            edit.click_save_changes_button
          end
        end
      end

      def create_request(api_endpoint)
        Runtime::API::Request.new(@api_client, api_endpoint)
      end
    end
  end
end
