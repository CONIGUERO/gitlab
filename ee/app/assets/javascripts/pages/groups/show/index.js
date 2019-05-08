import leaveByUrl from '~/namespaces/leave_by_url';
import initGroupDetails from '~/pages/groups/shared/group_details';
import initSecurityDashboard from 'ee/security_dashboard/index';

document.addEventListener('DOMContentLoaded', () => {
  leaveByUrl('group');

  if (document.querySelector('#js-group-security-dashboard')) {
    initSecurityDashboard();
  } else {
    initGroupDetails();
  }
});
