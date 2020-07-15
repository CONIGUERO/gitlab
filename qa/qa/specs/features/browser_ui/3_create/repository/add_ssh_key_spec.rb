# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'SSH keys support' do
      let(:key_title) { "key for ssh tests #{Time.current.to_f}" }

      it 'user adds and then removes an SSH key', :smoke do
        Flow::Login.sign_in

        key = Resource::SSHKey.fabricate_via_browser_ui! do |resource|
          resource.title = key_title
        end

        expect(page).to have_content(key.title)
        expect(page).to have_content(key.md5_fingerprint)

        Page::Main::Menu.perform(&:click_settings_link)
        Page::Profile::Menu.perform(&:click_ssh_keys)

        Page::Profile::SSHKeys.perform do |ssh_keys|
          ssh_keys.remove_key(key_title)
        end

        expect(page).not_to have_content("Title: #{key_title}")
        expect(page).not_to have_content(key.md5_fingerprint)
      end
    end
  end
end
