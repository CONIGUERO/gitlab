require_relative 'cop/gitlab/module_with_instance_variables'
require_relative 'cop/gitlab/predicate_memoization'
require_relative 'cop/gitlab/httparty'
require_relative 'cop/gitlab/finder_with_find_by'
require_relative 'cop/gitlab/union'
require_relative 'cop/include_action_view_context'
require_relative 'cop/include_sidekiq_worker'
require_relative 'cop/safe_params'
require_relative 'cop/active_record_association_reload'
require_relative 'cop/avoid_return_from_blocks'
require_relative 'cop/avoid_break_from_strong_memoize'
require_relative 'cop/avoid_route_redirect_leading_slash'
require_relative 'cop/line_break_around_conditional_block'
require_relative 'cop/prefer_class_methods_over_module'
require_relative 'cop/migration/add_column'
require_relative 'cop/migration/add_concurrent_foreign_key'
require_relative 'cop/migration/add_concurrent_index'
require_relative 'cop/migration/add_index'
require_relative 'cop/migration/add_reference'
require_relative 'cop/migration/add_timestamps'
require_relative 'cop/migration/datetime'
require_relative 'cop/migration/hash_index'
require_relative 'cop/migration/remove_column'
require_relative 'cop/migration/remove_concurrent_index'
require_relative 'cop/migration/remove_index'
require_relative 'cop/migration/reversible_add_column_with_default'
require_relative 'cop/migration/safer_boolean_column'
require_relative 'cop/migration/timestamps'
require_relative 'cop/migration/update_column_in_batches'
require_relative 'cop/migration/update_large_table'
require_relative 'cop/project_path_helper'
require_relative 'cop/rspec/env_assignment'
require_relative 'cop/rspec/factories_in_migration_specs'
require_relative 'cop/qa/element_with_pattern'
require_relative 'cop/sidekiq_options_queue'
require_relative 'cop/destroy_all'
require_relative 'cop/ruby_interpolation_in_translation'
require_relative 'code_reuse_helpers'
require_relative 'cop/code_reuse/finder'
require_relative 'cop/code_reuse/service_class'
require_relative 'cop/code_reuse/presenter'
require_relative 'cop/code_reuse/serializer'
require_relative 'cop/code_reuse/active_record'
require_relative 'cop/group_public_or_visible_to_user'
require_relative 'cop/inject_enterprise_edition_module'
