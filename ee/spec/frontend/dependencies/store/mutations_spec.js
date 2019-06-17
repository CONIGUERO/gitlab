import * as types from 'ee/dependencies/store/mutation_types';
import mutations from 'ee/dependencies/store/mutations';
import getInitialState from 'ee/dependencies/store/state';
import { REPORT_STATUS, SORT_ORDER } from 'ee/dependencies/store/constants';
import { TEST_HOST } from 'helpers/test_constants';

describe('Dependencies mutations', () => {
  let state;

  const errorLoadingState = () => ({
    isLoading: false,
    errorLoading: true,
    dependencies: [],
    pageInfo: {},
    initialized: true,
    reportInfo: {
      status: REPORT_STATUS.ok,
      jobPath: '',
    },
  });

  beforeEach(() => {
    state = getInitialState();
  });

  describe(types.SET_DEPENDENCIES_ENDPOINT, () => {
    it('sets the endpoint and download endpoint', () => {
      mutations[types.SET_DEPENDENCIES_ENDPOINT](state, TEST_HOST);

      expect(state.endpoint).toBe(TEST_HOST);
    });
  });

  describe(types.REQUEST_DEPENDENCIES_PAGINATION, () => {
    beforeEach(() => {
      mutations[types.REQUEST_DEPENDENCIES_PAGINATION](state);
    });

    it('correctly mutates the state', () => {
      expect(state.isLoading).toBe(true);
    });
  });

  describe(types.RECEIVE_DEPENDENCIES_PAGINATION_SUCCESS, () => {
    const total = 123;
    beforeEach(() => {
      mutations[types.RECEIVE_DEPENDENCIES_PAGINATION_SUCCESS](state, total);
    });

    it('correctly mutates the state', () => {
      expect(state.pageInfo.total).toBe(total);
    });
  });

  describe(types.RECEIVE_DEPENDENCIES_PAGINATION_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_DEPENDENCIES_PAGINATION_ERROR](state);
    });

    it('correctly mutates the state', () => {
      expect(state).toEqual(expect.objectContaining(errorLoadingState()));
    });
  });

  describe(types.REQUEST_DEPENDENCIES, () => {
    const page = 4;
    beforeEach(() => {
      mutations[types.REQUEST_DEPENDENCIES](state, { page });
    });

    it('correctly mutates the state', () => {
      expect(state.isLoading).toBe(true);
      expect(state.errorLoading).toBe(false);
      expect(state.pageInfo.page).toBe(page);
    });
  });

  describe(types.RECEIVE_DEPENDENCIES_SUCCESS, () => {
    const dependencies = [];
    const pageInfo = {};
    const reportInfo = {
      status: REPORT_STATUS.jobFailed,
      job_path: 'foo',
    };
    let originalPageInfo;

    beforeEach(() => {
      originalPageInfo = state.pageInfo;
      mutations[types.RECEIVE_DEPENDENCIES_SUCCESS](state, { dependencies, reportInfo, pageInfo });
    });

    it('correctly mutates the state', () => {
      expect(state).toEqual(
        expect.objectContaining({
          isLoading: false,
          errorLoading: false,
          dependencies,
          pageInfo: originalPageInfo,
          initialized: true,
          reportInfo: {
            status: REPORT_STATUS.jobFailed,
            jobPath: 'foo',
          },
        }),
      );
    });
  });

  describe(types.RECEIVE_DEPENDENCIES_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_DEPENDENCIES_ERROR](state);
    });

    it('correctly mutates the state', () => {
      expect(state).toEqual(expect.objectContaining(errorLoadingState()));
    });
  });

  describe(types.SET_SORT_FIELD, () => {
    it('sets the sort field', () => {
      const field = 'foo';
      mutations[types.SET_SORT_FIELD](state, field);

      expect(state.sortField).toBe(field);
    });
  });

  describe(types.TOGGLE_SORT_ORDER, () => {
    it('toggles the sort order', () => {
      const sortState = { sortOrder: SORT_ORDER.ascending };
      mutations[types.TOGGLE_SORT_ORDER](sortState);

      expect(sortState.sortOrder).toBe(SORT_ORDER.descending);

      mutations[types.TOGGLE_SORT_ORDER](sortState);

      expect(sortState.sortOrder).toBe(SORT_ORDER.ascending);
    });
  });
});
