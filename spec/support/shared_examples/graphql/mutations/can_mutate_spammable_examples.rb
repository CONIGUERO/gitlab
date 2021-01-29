# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'spam flag is present' do
  specify :aggregate_failures do
    subject

    expect(mutation_response).to have_key('spam')
    expect(mutation_response['spam']).to be_falsey
  end
end

RSpec.shared_examples 'can raise spam flag' do
  it 'spam parameters are passed to the service' do
    args = [anything, anything, hash_including(api: true, request: instance_of(ActionDispatch::Request))]
    expect(service).to receive(:new).with(*args).and_call_original

    subject
  end

  context 'when the snippet is detected as spam' do
    it 'raises spam flag' do
      allow_next_instance_of(Spam::SpamActionService) do |instance|
        allow(instance).to receive(:execute) { true }
        instance.target.spam!
        instance.target.unrecoverable_spam_error!
      end

      subject

      expect(mutation_response['spam']).to be true
      expect(mutation_response['errors']).to include("Your snippet has been recognized as spam and has been discarded.")
    end
  end
end