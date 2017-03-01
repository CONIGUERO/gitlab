require 'spec_helper'

describe API::Users, api: true  do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }
  let(:key)   { create(:key, user: user) }
  let(:email)   { create(:email, user: user) }
  let(:omniauth_user) { create(:omniauth_user) }
  let(:ldap_user) { create(:omniauth_user, provider: 'ldapmain') }
  let(:ldap_blocked_user) { create(:omniauth_user, provider: 'ldapmain', state: 'ldap_blocked') }
  let(:not_existing_user_id) { (User.maximum('id') || 0 ) + 10 }
  let(:not_existing_pat_id) { (PersonalAccessToken.maximum('id') || 0 ) + 10 }

  describe "GET /users" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/users")
        expect(response).to have_http_status(401)
      end
    end

    context "when authenticated" do
      # These specs are written just in case API authentication is not required anymore
      context "when public level is restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
          allow_any_instance_of(API::Helpers).to receive(:authenticate!).and_return(true)
        end

        it "renders 403" do
          get api("/users")
          expect(response).to have_http_status(403)
        end

        it "renders 404" do
          get api("/users/#{user.id}")
          expect(response).to have_http_status(404)
        end
      end

      it "returns an array of users" do
        get api("/users", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        username = user.username
        expect(json_response.detect do |user|
          user['username'] == username
        end['username']).to eq(username)
      end

      it "returns an array of blocked users" do
        ldap_blocked_user
        create(:user, state: 'blocked')

        get api("/users?blocked=true", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response).to all(include('state' => /(blocked|ldap_blocked)/))
      end

      it "returns one user" do
        get api("/users?username=#{omniauth_user.username}", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['username']).to eq(omniauth_user.username)
      end
    end

    context "when admin" do
      it "returns an array of users" do
        get api("/users", admin)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first.keys).to include 'email'
        expect(json_response.first.keys).to include 'organization'
        expect(json_response.first.keys).to include 'identities'
        expect(json_response.first.keys).to include 'can_create_project'
        expect(json_response.first.keys).to include 'two_factor_enabled'
        expect(json_response.first.keys).to include 'last_sign_in_at'
        expect(json_response.first.keys).to include 'confirmed_at'
      end

      it "returns an array of external users" do
        create(:user, external: true)

        get api("/users?external=true", admin)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response).to all(include('external' => true))
      end
    end
  end

  describe "GET /users/:id" do
    it "returns a user by id" do
      get api("/users/#{user.id}", user)
      expect(response).to have_http_status(200)
      expect(json_response['username']).to eq(user.username)
    end

    it "returns a 401 if unauthenticated" do
      get api("/users/9998")
      expect(response).to have_http_status(401)
    end

    it "returns a 404 error if user id not found" do
      get api("/users/9999", user)
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 for invalid ID" do
      get api("/users/1ASDF", user)

      expect(response).to have_http_status(404)
    end
  end

  describe "POST /users" do
    before{ admin }

    it "creates user" do
      expect do
        post api("/users", admin), attributes_for(:user, projects_limit: 3)
      end.to change { User.count }.by(1)
    end

    it "creates user with correct attributes" do
      post api('/users', admin), attributes_for(:user, admin: true, can_create_group: true)
      expect(response).to have_http_status(201)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user).not_to eq(nil)
      expect(new_user.admin).to eq(true)
      expect(new_user.can_create_group).to eq(true)
    end

    it "creates user with optional attributes" do
      optional_attributes = { confirm: true }
      attributes = attributes_for(:user).merge(optional_attributes)

      post api('/users', admin), attributes

      expect(response).to have_http_status(201)
    end

    it "creates non-admin user" do
      post api('/users', admin), attributes_for(:user, admin: false, can_create_group: false)
      expect(response).to have_http_status(201)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user).not_to eq(nil)
      expect(new_user.admin).to eq(false)
      expect(new_user.can_create_group).to eq(false)
    end

    it "creates non-admin users by default" do
      post api('/users', admin), attributes_for(:user)
      expect(response).to have_http_status(201)
      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user).not_to eq(nil)
      expect(new_user.admin).to eq(false)
    end

    it "returns 201 Created on success" do
      post api("/users", admin), attributes_for(:user, projects_limit: 3)
      expect(response).to have_http_status(201)
    end

    it 'creates non-external users by default' do
      post api("/users", admin), attributes_for(:user)
      expect(response).to have_http_status(201)

      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user).not_to eq nil
      expect(new_user.external).to be_falsy
    end

    it 'allows an external user to be created' do
      post api("/users", admin), attributes_for(:user, external: true)
      expect(response).to have_http_status(201)

      user_id = json_response['id']
      new_user = User.find(user_id)
      expect(new_user).not_to eq nil
      expect(new_user.external).to be_truthy
    end

    it "creates user with reset password" do
      post api('/users', admin), attributes_for(:user, reset_password: true).except(:password)

      expect(response).to have_http_status(201)

      user_id = json_response['id']
      new_user = User.find(user_id)

      expect(new_user).not_to eq(nil)
      expect(new_user.recently_sent_password_reset?).to eq(true)
    end

    it "does not create user with invalid email" do
      post api('/users', admin),
        email: 'invalid email',
        password: 'password',
        name: 'test'
      expect(response).to have_http_status(400)
    end

    it 'returns 400 error if name not given' do
      post api('/users', admin), attributes_for(:user).except(:name)
      expect(response).to have_http_status(400)
    end

    it 'returns 400 error if password not given' do
      post api('/users', admin), attributes_for(:user).except(:password)
      expect(response).to have_http_status(400)
    end

    it 'returns 400 error if email not given' do
      post api('/users', admin), attributes_for(:user).except(:email)
      expect(response).to have_http_status(400)
    end

    it 'returns 400 error if username not given' do
      post api('/users', admin), attributes_for(:user).except(:username)
      expect(response).to have_http_status(400)
    end

    it 'returns 400 error if user does not validate' do
      post api('/users', admin),
        password: 'pass',
        email: 'test@example.com',
        username: 'test!',
        name: 'test',
        bio: 'g' * 256,
        projects_limit: -1
      expect(response).to have_http_status(400)
      expect(json_response['message']['password']).
        to eq(['is too short (minimum is 8 characters)'])
      expect(json_response['message']['bio']).
        to eq(['is too long (maximum is 255 characters)'])
      expect(json_response['message']['projects_limit']).
        to eq(['must be greater than or equal to 0'])
      expect(json_response['message']['username']).
        to eq([Gitlab::Regex.namespace_regex_message])
    end

    it "is not available for non admin users" do
      post api("/users", user), attributes_for(:user)
      expect(response).to have_http_status(403)
    end

    context 'with existing user' do
      before do
        post api('/users', admin),
          email: 'test@example.com',
          password: 'password',
          username: 'test',
          name: 'foo'
      end

      it 'returns 409 conflict error if user with same email exists' do
        expect do
          post api('/users', admin),
            name: 'foo',
            email: 'test@example.com',
            password: 'password',
            username: 'foo'
        end.to change { User.count }.by(0)
        expect(response).to have_http_status(409)
        expect(json_response['message']).to eq('Email has already been taken')
      end

      it 'returns 409 conflict error if same username exists' do
        expect do
          post api('/users', admin),
            name: 'foo',
            email: 'foo@example.com',
            password: 'password',
            username: 'test'
        end.to change { User.count }.by(0)
        expect(response).to have_http_status(409)
        expect(json_response['message']).to eq('Username has already been taken')
      end

      it 'creates user with new identity' do
        post api("/users", admin), attributes_for(:user, provider: 'github', extern_uid: '67890')

        expect(response).to have_http_status(201)
        expect(json_response['identities'].first['extern_uid']).to eq('67890')
        expect(json_response['identities'].first['provider']).to eq('github')
      end
    end
  end

  describe "GET /users/sign_up" do
    it "redirects to sign in page" do
      get "/users/sign_up"
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "PUT /users/:id" do
    let!(:admin_user) { create(:admin) }

    before { admin }

    it "updates user with new bio" do
      put api("/users/#{user.id}", admin), { bio: 'new test bio' }
      expect(response).to have_http_status(200)
      expect(json_response['bio']).to eq('new test bio')
      expect(user.reload.bio).to eq('new test bio')
    end

    it "updates user with new password and forces reset on next login" do
      put api("/users/#{user.id}", admin), password: '12345678'

      expect(response).to have_http_status(200)
      expect(user.reload.password_expires_at).to be <= Time.now
    end

    it "updates user with organization" do
      put api("/users/#{user.id}", admin), { organization: 'GitLab' }

      expect(response).to have_http_status(200)
      expect(json_response['organization']).to eq('GitLab')
      expect(user.reload.organization).to eq('GitLab')
    end

    it 'updates user with his own email' do
      put api("/users/#{user.id}", admin), email: user.email
      expect(response).to have_http_status(200)
      expect(json_response['email']).to eq(user.email)
      expect(user.reload.email).to eq(user.email)
    end

    it 'updates user with his own username' do
      put api("/users/#{user.id}", admin), username: user.username
      expect(response).to have_http_status(200)
      expect(json_response['username']).to eq(user.username)
      expect(user.reload.username).to eq(user.username)
    end

    it "updates user's existing identity" do
      put api("/users/#{omniauth_user.id}", admin), provider: 'ldapmain', extern_uid: '654321'
      expect(response).to have_http_status(200)
      expect(omniauth_user.reload.identities.first.extern_uid).to eq('654321')
    end

    it 'updates user with new identity' do
      put api("/users/#{user.id}", admin), provider: 'github', extern_uid: 'john'
      expect(response).to have_http_status(200)
      expect(user.reload.identities.first.extern_uid).to eq('john')
      expect(user.reload.identities.first.provider).to eq('github')
    end

    it "updates admin status" do
      put api("/users/#{user.id}", admin), { admin: true }
      expect(response).to have_http_status(200)
      expect(json_response['is_admin']).to eq(true)
      expect(user.reload.admin).to eq(true)
    end

    it "updates external status" do
      put api("/users/#{user.id}", admin), { external: true }
      expect(response.status).to eq 200
      expect(json_response['external']).to eq(true)
      expect(user.reload.external?).to be_truthy
    end

    it "does not update admin status" do
      put api("/users/#{admin_user.id}", admin), { can_create_group: false }
      expect(response).to have_http_status(200)
      expect(json_response['is_admin']).to eq(true)
      expect(admin_user.reload.admin).to eq(true)
      expect(admin_user.can_create_group).to eq(false)
    end

    it "does not allow invalid update" do
      put api("/users/#{user.id}", admin), { email: 'invalid email' }
      expect(response).to have_http_status(400)
      expect(user.reload.email).not_to eq('invalid email')
    end

    it "is not available for non admin users" do
      put api("/users/#{user.id}", user), attributes_for(:user)
      expect(response).to have_http_status(403)
    end

    it "returns 404 for non-existing user" do
      put api("/users/999999", admin), { bio: 'update should fail' }
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 if invalid ID" do
      put api("/users/ASDF", admin)

      expect(response).to have_http_status(404)
    end

    it 'returns 400 error if user does not validate' do
      put api("/users/#{user.id}", admin),
        password: 'pass',
        email: 'test@example.com',
        username: 'test!',
        name: 'test',
        bio: 'g' * 256,
        projects_limit: -1
      expect(response).to have_http_status(400)
      expect(json_response['message']['password']).
        to eq(['is too short (minimum is 8 characters)'])
      expect(json_response['message']['bio']).
        to eq(['is too long (maximum is 255 characters)'])
      expect(json_response['message']['projects_limit']).
        to eq(['must be greater than or equal to 0'])
      expect(json_response['message']['username']).
        to eq([Gitlab::Regex.namespace_regex_message])
    end

    it 'returns 400 if provider is missing for identity update' do
      put api("/users/#{omniauth_user.id}", admin), extern_uid: '654321'

      expect(response).to have_http_status(400)
    end

    it 'returns 400 if external UID is missing for identity update' do
      put api("/users/#{omniauth_user.id}", admin), provider: 'ldap'

      expect(response).to have_http_status(400)
    end

    context "with existing user" do
      before do
        post api("/users", admin), { email: 'test@example.com', password: 'password', username: 'test', name: 'test' }
        post api("/users", admin), { email: 'foo@bar.com', password: 'password', username: 'john', name: 'john' }
        @user = User.all.last
      end

      it 'returns 409 conflict error if email address exists' do
        put api("/users/#{@user.id}", admin), email: 'test@example.com'
        expect(response).to have_http_status(409)
        expect(@user.reload.email).to eq(@user.email)
      end

      it 'returns 409 conflict error if username taken' do
        @user_id = User.all.last.id
        put api("/users/#{@user.id}", admin), username: 'test'
        expect(response).to have_http_status(409)
        expect(@user.reload.username).to eq(@user.username)
      end
    end
  end

  describe "POST /users/:id/keys" do
    before { admin }

    it "does not create invalid ssh key" do
      post api("/users/#{user.id}/keys", admin), { title: "invalid key" }

      expect(response).to have_http_status(400)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'does not create key without title' do
      post api("/users/#{user.id}/keys", admin), key: 'some key'

      expect(response).to have_http_status(400)
      expect(json_response['error']).to eq('title is missing')
    end

    it "creates ssh key" do
      key_attrs = attributes_for :key
      expect do
        post api("/users/#{user.id}/keys", admin), key_attrs
      end.to change{ user.keys.count }.by(1)
    end

    it "returns 400 for invalid ID" do
      post api("/users/999999/keys", admin)
      expect(response).to have_http_status(400)
    end
  end

  describe 'GET /user/:id/keys' do
    before { admin }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api("/users/#{user.id}/keys")
        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'returns 404 for non-existing user' do
        get api('/users/999999/keys', admin)
        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns array of ssh keys' do
        user.keys << key
        user.save

        get api("/users/#{user.id}/keys", admin)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['title']).to eq(key.title)
      end
    end
  end

  describe 'DELETE /user/:id/keys/:key_id' do
    before { admin }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        delete api("/users/#{user.id}/keys/42")
        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'deletes existing key' do
        user.keys << key
        user.save

        expect do
          delete api("/users/#{user.id}/keys/#{key.id}", admin)

          expect(response).to have_http_status(204)
        end.to change { user.keys.count }.by(-1)
      end

      it 'returns 404 error if user not found' do
        user.keys << key
        user.save
        delete api("/users/999999/keys/#{key.id}", admin)
        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if key not foud' do
        delete api("/users/#{user.id}/keys/42", admin)
        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Key Not Found')
      end
    end
  end

  describe "POST /users/:id/emails" do
    before { admin }

    it "does not create invalid email" do
      post api("/users/#{user.id}/emails", admin), {}

      expect(response).to have_http_status(400)
      expect(json_response['error']).to eq('email is missing')
    end

    it "creates email" do
      email_attrs = attributes_for :email
      expect do
        post api("/users/#{user.id}/emails", admin), email_attrs
      end.to change{ user.emails.count }.by(1)
    end

    it "returns a 400 for invalid ID" do
      post api("/users/999999/emails", admin)

      expect(response).to have_http_status(400)
    end
  end

  describe 'GET /user/:id/emails' do
    before { admin }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api("/users/#{user.id}/emails")
        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'returns 404 for non-existing user' do
        get api('/users/999999/emails', admin)
        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns array of emails' do
        user.emails << email
        user.save

        get api("/users/#{user.id}/emails", admin)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['email']).to eq(email.email)
      end

      it "returns a 404 for invalid ID" do
        put api("/users/ASDF/emails", admin)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'DELETE /user/:id/emails/:email_id' do
    before { admin }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        delete api("/users/#{user.id}/emails/42")
        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'deletes existing email' do
        user.emails << email
        user.save

        expect do
          delete api("/users/#{user.id}/emails/#{email.id}", admin)

          expect(response).to have_http_status(204)
        end.to change { user.emails.count }.by(-1)
      end

      it 'returns 404 error if user not found' do
        user.emails << email
        user.save
        delete api("/users/999999/emails/#{email.id}", admin)
        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 404 error if email not foud' do
        delete api("/users/#{user.id}/emails/42", admin)
        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Email Not Found')
      end

      it "returns a 404 for invalid ID" do
        delete api("/users/ASDF/emails/bar", admin)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe "DELETE /users/:id" do
    let!(:namespace) { user.namespace }
    before { admin }

    it "deletes user" do
      delete api("/users/#{user.id}", admin)

      expect(response).to have_http_status(204)
      expect { User.find(user.id) }.to raise_error ActiveRecord::RecordNotFound
      expect { Namespace.find(namespace.id) }.to raise_error ActiveRecord::RecordNotFound
    end

    it "does not delete for unauthenticated user" do
      delete api("/users/#{user.id}")
      expect(response).to have_http_status(401)
    end

    it "is not available for non admin users" do
      delete api("/users/#{user.id}", user)
      expect(response).to have_http_status(403)
    end

    it "returns 404 for non-existing user" do
      delete api("/users/999999", admin)
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 for invalid ID" do
      delete api("/users/ASDF", admin)

      expect(response).to have_http_status(404)
    end
  end

  describe "GET /user" do
    let(:personal_access_token) { create(:personal_access_token, user: user).token }

    context 'with regular user' do
      context 'with personal access token' do
        it 'returns 403 without private token when sudo is defined' do
          get api("/user?private_token=#{personal_access_token}&sudo=123")

          expect(response).to have_http_status(403)
        end
      end

      context 'with private token' do
        it 'returns 403 without private token when sudo defined' do
          get api("/user?private_token=#{user.private_token}&sudo=123")

          expect(response).to have_http_status(403)
        end
      end

      it 'returns current user without private token when sudo not defined' do
        get api("/user", user)

        expect(response).to have_http_status(200)
        expect(response).to match_response_schema('user/public')
        expect(json_response['id']).to eq(user.id)
      end
    end

    context 'with admin' do
      let(:admin_personal_access_token) { create(:personal_access_token, user: admin).token }

      context 'with personal access token' do
        it 'returns 403 without private token when sudo defined' do
          get api("/user?private_token=#{admin_personal_access_token}&sudo=#{user.id}")

          expect(response).to have_http_status(403)
        end

        it 'returns initial current user without private token when sudo not defined' do
          get api("/user?private_token=#{admin_personal_access_token}")

          expect(response).to have_http_status(200)
          expect(response).to match_response_schema('user/public')
          expect(json_response['id']).to eq(admin.id)
        end
      end

      context 'with private token' do
        it 'returns sudoed user with private token when sudo defined' do
          get api("/user?private_token=#{admin.private_token}&sudo=#{user.id}")

          expect(response).to have_http_status(200)
          expect(response).to match_response_schema('user/login')
          expect(json_response['id']).to eq(user.id)
        end

        it 'returns initial current user without private token when sudo not defined' do
          get api("/user?private_token=#{admin.private_token}")

          expect(response).to have_http_status(200)
          expect(response).to match_response_schema('user/public')
          expect(json_response['id']).to eq(admin.id)
        end
      end
    end

    context 'with unauthenticated user' do
      it "returns 401 error if user is unauthenticated" do
        get api("/user")

        expect(response).to have_http_status(401)
      end
    end
  end

  describe "GET /user/keys" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/user/keys")
        expect(response).to have_http_status(401)
      end
    end

    context "when authenticated" do
      it "returns array of ssh keys" do
        user.keys << key
        user.save

        get api("/user/keys", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first["title"]).to eq(key.title)
      end
    end
  end

  describe "GET /user/keys/:key_id" do
    it "returns single key" do
      user.keys << key
      user.save
      get api("/user/keys/#{key.id}", user)
      expect(response).to have_http_status(200)
      expect(json_response["title"]).to eq(key.title)
    end

    it "returns 404 Not Found within invalid ID" do
      get api("/user/keys/42", user)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 Key Not Found')
    end

    it "returns 404 error if admin accesses user's ssh key" do
      user.keys << key
      user.save
      admin
      get api("/user/keys/#{key.id}", admin)
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 Key Not Found')
    end

    it "returns 404 for invalid ID" do
      get api("/users/keys/ASDF", admin)

      expect(response).to have_http_status(404)
    end
  end

  describe "POST /user/keys" do
    it "creates ssh key" do
      key_attrs = attributes_for :key
      expect do
        post api("/user/keys", user), key_attrs
      end.to change{ user.keys.count }.by(1)
      expect(response).to have_http_status(201)
    end

    it "returns a 401 error if unauthorized" do
      post api("/user/keys"), title: 'some title', key: 'some key'
      expect(response).to have_http_status(401)
    end

    it "does not create ssh key without key" do
      post api("/user/keys", user), title: 'title'

      expect(response).to have_http_status(400)
      expect(json_response['error']).to eq('key is missing')
    end

    it 'does not create ssh key without title' do
      post api('/user/keys', user), key: 'some key'

      expect(response).to have_http_status(400)
      expect(json_response['error']).to eq('title is missing')
    end

    it "does not create ssh key without title" do
      post api("/user/keys", user), key: "somekey"
      expect(response).to have_http_status(400)
    end
  end

  describe "DELETE /user/keys/:key_id" do
    it "deletes existed key" do
      user.keys << key
      user.save

      expect do
        delete api("/user/keys/#{key.id}", user)

        expect(response).to have_http_status(204)
      end.to change{user.keys.count}.by(-1)
    end

    it "returns 404 if key ID not found" do
      delete api("/user/keys/42", user)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 Key Not Found')
    end

    it "returns 401 error if unauthorized" do
      user.keys << key
      user.save
      delete api("/user/keys/#{key.id}")
      expect(response).to have_http_status(401)
    end

    it "returns a 404 for invalid ID" do
      delete api("/users/keys/ASDF", admin)

      expect(response).to have_http_status(404)
    end
  end

  describe "GET /user/emails" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/user/emails")
        expect(response).to have_http_status(401)
      end
    end

    context "when authenticated" do
      it "returns array of emails" do
        user.emails << email
        user.save

        get api("/user/emails", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first["email"]).to eq(email.email)
      end
    end
  end

  describe "GET /user/emails/:email_id" do
    it "returns single email" do
      user.emails << email
      user.save
      get api("/user/emails/#{email.id}", user)
      expect(response).to have_http_status(200)
      expect(json_response["email"]).to eq(email.email)
    end

    it "returns 404 Not Found within invalid ID" do
      get api("/user/emails/42", user)
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 Email Not Found')
    end

    it "returns 404 error if admin accesses user's email" do
      user.emails << email
      user.save
      admin
      get api("/user/emails/#{email.id}", admin)
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 Email Not Found')
    end

    it "returns 404 for invalid ID" do
      get api("/users/emails/ASDF", admin)

      expect(response).to have_http_status(404)
    end
  end

  describe "POST /user/emails" do
    it "creates email" do
      email_attrs = attributes_for :email
      expect do
        post api("/user/emails", user), email_attrs
      end.to change{ user.emails.count }.by(1)
      expect(response).to have_http_status(201)
    end

    it "returns a 401 error if unauthorized" do
      post api("/user/emails"), email: 'some email'
      expect(response).to have_http_status(401)
    end

    it "does not create email with invalid email" do
      post api("/user/emails", user), {}

      expect(response).to have_http_status(400)
      expect(json_response['error']).to eq('email is missing')
    end
  end

  describe "DELETE /user/emails/:email_id" do
    it "deletes existed email" do
      user.emails << email
      user.save

      expect do
        delete api("/user/emails/#{email.id}", user)

        expect(response).to have_http_status(204)
      end.to change{user.emails.count}.by(-1)
    end

    it "returns 404 if email ID not found" do
      delete api("/user/emails/42", user)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 Email Not Found')
    end

    it "returns 401 error if unauthorized" do
      user.emails << email
      user.save
      delete api("/user/emails/#{email.id}")
      expect(response).to have_http_status(401)
    end

    it "returns 400 for invalid ID" do
      delete api("/user/emails/ASDF", admin)

      expect(response).to have_http_status(400)
    end
  end

  describe 'POST /users/:id/block' do
    before { admin }
    it 'blocks existing user' do
      post api("/users/#{user.id}/block", admin)
      expect(response).to have_http_status(201)
      expect(user.reload.state).to eq('blocked')
    end

    it 'does not re-block ldap blocked users' do
      post api("/users/#{ldap_blocked_user.id}/block", admin)
      expect(response).to have_http_status(403)
      expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
    end

    it 'does not be available for non admin users' do
      post api("/users/#{user.id}/block", user)
      expect(response).to have_http_status(403)
      expect(user.reload.state).to eq('active')
    end

    it 'returns a 404 error if user id not found' do
      post api('/users/9999/block', admin)
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end
  end

  describe 'POST /users/:id/unblock' do
    let(:blocked_user)  { create(:user, state: 'blocked') }
    before { admin }

    it 'unblocks existing user' do
      post api("/users/#{user.id}/unblock", admin)
      expect(response).to have_http_status(201)
      expect(user.reload.state).to eq('active')
    end

    it 'unblocks a blocked user' do
      post api("/users/#{blocked_user.id}/unblock", admin)
      expect(response).to have_http_status(201)
      expect(blocked_user.reload.state).to eq('active')
    end

    it 'does not unblock ldap blocked users' do
      post api("/users/#{ldap_blocked_user.id}/unblock", admin)
      expect(response).to have_http_status(403)
      expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
    end

    it 'does not be available for non admin users' do
      post api("/users/#{user.id}/unblock", user)
      expect(response).to have_http_status(403)
      expect(user.reload.state).to eq('active')
    end

    it 'returns a 404 error if user id not found' do
      post api('/users/9999/block', admin)
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 for invalid ID" do
      post api("/users/ASDF/block", admin)

      expect(response).to have_http_status(404)
    end
  end

  describe 'GET /users/:id/events' do
    let(:user) { create(:user) }
    let(:project) { create(:empty_project) }
    let(:note) { create(:note_on_issue, note: 'What an awesome day!', project: project) }

    before do
      project.add_user(user, :developer)
      EventCreateService.new.leave_note(note, user)
    end

    context "as a user than cannot see the event's project" do
      it 'returns no events' do
        other_user = create(:user)

        get api("/users/#{user.id}/events", other_user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_empty
      end
    end

    context "as a user than can see the event's project" do
      context 'joined event' do
        it 'returns the "joined" event' do
          get api("/users/#{user.id}/events", user)

          expect(response).to have_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array

          comment_event = json_response.find { |e| e['action_name'] == 'commented on' }

          expect(comment_event['project_id'].to_i).to eq(project.id)
          expect(comment_event['author_username']).to eq(user.username)
          expect(comment_event['note']['id']).to eq(note.id)
          expect(comment_event['note']['body']).to eq('What an awesome day!')

          joined_event = json_response.find { |e| e['action_name'] == 'joined' }

          expect(joined_event['project_id'].to_i).to eq(project.id)
          expect(joined_event['author_username']).to eq(user.username)
          expect(joined_event['author']['name']).to eq(user.name)
        end
      end

      context 'when there are multiple events from different projects' do
        let(:second_note) { create(:note_on_issue, project: create(:empty_project)) }
        let(:third_note) { create(:note_on_issue, project: project) }

        before do
          second_note.project.add_user(user, :developer)

          [second_note, third_note].each do |note|
            EventCreateService.new.leave_note(note, user)
          end
        end

        it 'returns events in the correct order (from newest to oldest)' do
          get api("/users/#{user.id}/events", user)

          comment_events = json_response.select { |e| e['action_name'] == 'commented on' }

          expect(comment_events[0]['target_id']).to eq(third_note.id)
          expect(comment_events[1]['target_id']).to eq(second_note.id)
          expect(comment_events[2]['target_id']).to eq(note.id)
        end
      end
    end

    it 'returns a 404 error if not found' do
      get api('/users/42/events', user)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end
  end

  describe 'GET /users/:user_id/impersonation_tokens' do
    let!(:active_personal_access_token) { create(:personal_access_token, user: user) }
    let!(:revoked_personal_access_token) { create(:personal_access_token, :revoked, user: user) }
    let!(:expired_personal_access_token) { create(:personal_access_token, :expired, user: user) }
    let!(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }
    let!(:revoked_impersonation_token) { create(:personal_access_token, :impersonation, :revoked, user: user) }

    it 'returns a 404 error if user not found' do
      get api("/users/#{not_existing_user_id}/impersonation_tokens", admin)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      get api("/users/#{not_existing_user_id}/impersonation_tokens", user)

      expect(response).to have_http_status(403)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'returns an array of all impersonated tokens' do
      get api("/users/#{user.id}/impersonation_tokens", admin)

      expect(response).to have_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(2)
    end

    it 'returns an array of active impersonation tokens if state active' do
      get api("/users/#{user.id}/impersonation_tokens?state=active", admin)

      expect(response).to have_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(1)
      expect(json_response).to all(include('active' => true))
    end

    it 'returns an array of inactive personal access tokens if active is set to false' do
      get api("/users/#{user.id}/impersonation_tokens?state=inactive", admin)

      expect(response).to have_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(1)
      expect(json_response).to all(include('active' => false))
    end
  end

  describe 'POST /users/:user_id/impersonation_tokens' do
    let(:name) { 'my new pat' }
    let(:expires_at) { '2016-12-28' }
    let(:scopes) { %w(api read_user) }
    let(:impersonation) { true }

    it 'returns validation error if impersonation token misses some attributes' do
      post api("/users/#{user.id}/impersonation_tokens", admin)

      expect(response).to have_http_status(400)
      expect(json_response['error']).to eq('name is missing')
    end

    it 'returns a 404 error if user not found' do
      post api("/users/#{not_existing_user_id}/impersonation_tokens", admin),
        name: name,
        expires_at: expires_at

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      post api("/users/#{user.id}/impersonation_tokens", user),
        name: name,
        expires_at: expires_at

      expect(response).to have_http_status(403)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'creates a impersonation token' do
      post api("/users/#{user.id}/impersonation_tokens", admin),
        name: name,
        expires_at: expires_at,
        scopes: scopes,
        impersonation: impersonation

      expect(response).to have_http_status(201)
      expect(json_response['name']).to eq(name)
      expect(json_response['scopes']).to eq(scopes)
      expect(json_response['expires_at']).to eq(expires_at)
      expect(json_response['id']).to be_present
      expect(json_response['created_at']).to be_present
      expect(json_response['active']).to be_falsey
      expect(json_response['revoked']).to be_falsey
      expect(json_response['token']).to be_present
      expect(json_response['impersonation']).to eq(impersonation)
    end
  end

  describe 'GET /users/:user_id/impersonation_tokens/:impersonation_token_id' do
    let!(:personal_access_token) { create(:personal_access_token, user: user) }
    let!(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }

    it 'returns 404 error if user not found' do
      get api("/users/#{not_existing_user_id}/impersonation_tokens/1", admin)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 404 error if impersonation token not found' do
      get api("/users/#{user.id}/impersonation_tokens/#{not_existing_pat_id}", admin)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 404 error if token is not impersonation token' do
      get api("/users/#{user.id}/impersonation_tokens/#{personal_access_token.id}", admin)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      get api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", user)

      expect(response).to have_http_status(403)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'returns a personal access token' do
      get api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", admin)

      expect(response).to have_http_status(200)
      expect(json_response['token']).to be_present
      expect(json_response['impersonation']).to be_truthy
    end
  end

  describe 'DELETE /users/:user_id/impersonation_tokens/:impersonation_token_id' do
    let!(:personal_access_token) { create(:personal_access_token, user: user) }
    let!(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }

    it 'returns a 404 error if user not found' do
      delete api("/users/#{not_existing_user_id}/impersonation_tokens/1", admin)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it 'returns a 404 error if impersonation token not found' do
      delete api("/users/#{user.id}/impersonation_tokens/#{not_existing_pat_id}", admin)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 404 error if token is not impersonation token' do
      delete api("/users/#{user.id}/impersonation_tokens/#{personal_access_token.id}", admin)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 Impersonation Token Not Found')
    end

    it 'returns a 403 error when authenticated as normal user' do
      delete api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", user)

      expect(response).to have_http_status(403)
      expect(json_response['message']).to eq('403 Forbidden')
    end

    it 'revokes a impersonation token' do
      delete api("/users/#{user.id}/impersonation_tokens/#{impersonation_token.id}", admin)

      expect(response).to have_http_status(204)
      expect(impersonation_token.revoked).to be_falsey
      expect(impersonation_token.reload.revoked).to be_truthy
    end
  end
end
