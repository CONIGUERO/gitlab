# frozen_string_literal: true

class AdjournedGroupDeletionWorker
  include ApplicationWorker
  include CronjobQueue

  INTERVAL = 5.minutes.to_i

  feature_category :authentication_and_authorization

  def perform
    deletion_cutoff = Gitlab::CurrentSettings.deletion_adjourned_period.days.ago.to_date

    Group.with_route.aimed_for_deletion(deletion_cutoff)
      .with_deletion_schedule
      .find_each(batch_size: 100) # rubocop: disable CodeReuse/ActiveRecord
      .with_index do |group, index|
      deletion_schedule = group.deletion_schedule
      delay = index * INTERVAL

      with_context(namespace: group, user: deletion_schedule.deleting_user) do
        GroupDestroyWorker.perform_in(delay, group.id, deletion_schedule.user_id)
      end
    end
  end
end
