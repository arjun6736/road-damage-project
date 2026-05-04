import axios from 'axios';

export const API = axios.create({
  baseURL: 'https://routefixer.dpdns.org/api',
  headers: {
    Accept: 'application/json'
  }
});

export const fetchReports = (params) =>
  API.get('/admin/reports/', { params });

export const fetchDashboardStats = () =>
  API.get('/dashboard/stats/');

export const fetchReportsBySegment = (segmentId, params, options = {}) =>
  API.get(`/reports/segment/${segmentId}/`, { params, signal: options.signal });