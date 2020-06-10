# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Approvable do
  subject(:merge_request) { create(:merge_request) }

  let(:project) { merge_request.project }
  let(:author) { merge_request.author }

  describe '#approval_feature_available?' do
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

    subject { merge_request.approval_feature_available? }

    it 'is false when feature is disabled' do
      allow(project).to receive(:feature_available?).with(:merge_request_approvers).and_return(false)

      is_expected.to be false
    end

    it 'is true when feature is enabled' do
      allow(project).to receive(:feature_available?).with(:merge_request_approvers).and_return(true)

      is_expected.to be true
    end
  end

  describe "#approvals_given" do
    subject { merge_request.approvals_given }

    it "returns the correct number of approvals given" do
      approval_state = double("approval_state", approvals_required: 5, approvals_left: 3)
      allow(merge_request).to receive(:approval_state).and_return(approval_state)

      expect(subject).to eq(approval_state.approvals_required - approval_state.approvals_left)
    end
  end

  described_class::FORWARDABLE_METHODS.each do |method|
    it { is_expected.to delegate_method(method).to(:approval_state) }
  end
end
