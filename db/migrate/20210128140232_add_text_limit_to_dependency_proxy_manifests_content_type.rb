# frozen_string_literal: true

class AddTextLimitToDependencyProxyManifestsContentType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :dependency_proxy_manifests, :content_type, 255
  end

  def down
    remove_text_limit :dependency_proxy_manifests, :content_type
  end
end
