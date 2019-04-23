# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Geo::Fdw::UploadRegistryQueryBuilder, :geo, :geo_fdw do
  let(:project) { create(:project) }
  let(:upload_1) { create(:upload, :issuable_upload, model: project) }
  let(:upload_2) { create(:upload, :issuable_upload, model: project) }
  let(:upload_3) { create(:upload, :issuable_upload) }
  let!(:file_registry_1) { create(:geo_file_registry, file_id: upload_1.id) }
  let!(:file_registry_2) { create(:geo_file_registry, :attachment, file_id: upload_2.id) }
  let!(:file_registry_3) { create(:geo_file_registry, file_id: upload_3.id) }

  describe '#for_model' do
    it 'returns registries that upload belong to the model' do
      expect(subject.for_model(project)).to match_ids(file_registry_1, file_registry_2)
    end
  end

  describe '#with_type' do
    it 'returns registries filtered by file_type' do
      expect(subject.with_type('file')).to match_ids(file_registry_1, file_registry_3)
    end
  end
end
