import types from './mutation_types';

export function setActiveTab({ commit }, tab) {
  commit(types.SET_ACTIVE_TAB, tab);
}

export function setEndpoints({ commit }, endpoints) {
  commit(types.SET_ENDPOINTS, endpoints);
}

export function setMrMetadata({ commit }, metadata) {
  commit(types.SET_MR_METADATA, metadata);
}
