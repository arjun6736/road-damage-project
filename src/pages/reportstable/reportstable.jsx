import { useState, useEffect, useCallback } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { fetchReports, fetchReportsBySegment } from 'api/reports';
import {
  Box, Stack, Typography, IconButton, Menu, MenuItem,
  TextField, Button, Drawer, Divider, CircularProgress, Chip
} from '@mui/material';

// Components & Icons
import OrdersTable from 'sections/dashboard/default/OrdersTable';
import EllipsisOutlined from '@ant-design/icons/EllipsisOutlined';
import FilterOutlined from '@ant-design/icons/FilterOutlined';
import SortAscendingOutlined from '@ant-design/icons/SortAscendingOutlined';
import SortDescendingOutlined from '@ant-design/icons/SortDescendingOutlined';
import CloseOutlined from '@ant-design/icons/CloseOutlined';

function useDebounce(value, delay) {
  const [debouncedValue, setDebouncedValue] = useState(value);
  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(handler);
  }, [value, delay]);
  return debouncedValue;
}

export default function ReportsTable() {
  // --- Router State ---
  const location = useLocation();
  const navigate = useNavigate();

  // Initialize from navigation state (if coming from map)
  const [activeSegmentId, setActiveSegmentId] = useState(location.state?.segmentId || null);

  // --- Data State ---
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);

  // --- UI State ---
  const [menuAnchor, setMenuAnchor] = useState(null);
  const [filterOpen, setFilterOpen] = useState(false);

  // --- Filter State ---
  const [search, setSearch] = useState('');
  const debouncedSearch = useDebounce(search, 500);

  const [filters, setFilters] = useState({
    status: 'All',
    severity: 'All',
    fromDate: '',
    toDate: '',
    sortOrder: 'new'
  });

  // --- API Logic ---
  const loadReports = useCallback(async (signal) => {
    try {
      setLoading(true);

      const params = {
        search: debouncedSearch || undefined,
        status: filters.status !== 'All' ? filters.status : undefined,
        severity: filters.severity !== 'All' ? filters.severity : undefined,
        from_date: filters.fromDate || undefined,
        to_date: filters.toDate || undefined,
        ordering: filters.sortOrder === 'new' ? '-timestamp' : 'timestamp'
      };

      // ✅ FIX: Use the shared API instance for both paths (consistent headers + baseURL)
      const res = activeSegmentId
        ? await fetchReportsBySegment(activeSegmentId, params, { signal })
        : await fetchReports(params, { signal });

      const data = res.data;

      if (Array.isArray(data)) {
        // Case 1: API returns a direct array [ ... ]
        setReports(data);
      } else if (data && Array.isArray(data.results)) {
        // Case 2: Paginated response { count, results: [ ... ] }
        setReports(data.results);
      } else if (data && Array.isArray(data.reports)) {
        // Case 3: Segment response { success, segment_id, total_reports, reports: [ ... ] }
        setReports(data.reports);
      } else {
        // Case 4: Unexpected format fallback
        console.warn('Unexpected API response format:', data);
        setReports([]);
      }

    } catch (err) {
      if (err.name !== 'CanceledError') {
        console.error('Failed to fetch reports:', err);
        setReports([]);
      }
    } finally {
      setLoading(false);
    }
  }, [debouncedSearch, filters, activeSegmentId]);

  useEffect(() => {
    const controller = new AbortController();
    loadReports(controller.signal);
    return () => controller.abort();
  }, [loadReports]);

  // --- Handlers ---
  const handleFilterChange = (field) => (e) => {
    setFilters(prev => ({ ...prev, [field]: e.target.value }));
  };

  const toggleSort = () => {
    setFilters(prev => ({ ...prev, sortOrder: prev.sortOrder === 'new' ? 'old' : 'new' }));
  };

  const clearSegmentFilter = () => {
    setActiveSegmentId(null);
    navigate(location.pathname, { replace: true, state: {} });
  };

  return (
    <Box sx={{ width: '100%' }}>
      {/* ===== Sticky Top Bar ===== */}
      <Box sx={{
        position: 'sticky', top: 0, zIndex: 1100,
        backgroundColor: 'background.paper', borderBottom: '1px solid',
        borderColor: 'divider', px: 2, py: 1
      }}>
        <Stack direction="row" spacing={2} alignItems="center" justifyContent="space-between">

          <Stack direction="row" alignItems="center" spacing={1}>
            <Typography variant="h5">Reports</Typography>
            {activeSegmentId && (
              <Chip
                label={`Segment #${activeSegmentId}`}
                color="primary"
                onDelete={clearSegmentFilter}
                deleteIcon={<CloseOutlined />}
              />
            )}
          </Stack>

          <Stack direction="row" spacing={1} alignItems="center">
            <TextField
              size="small"
              placeholder="Search..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
            <Button
              variant="outlined"
              startIcon={filters.sortOrder === 'new' ? <SortDescendingOutlined /> : <SortAscendingOutlined />}
              onClick={toggleSort}
            >
              {filters.sortOrder === 'new' ? 'Newest' : 'Oldest'}
            </Button>
            <Button
              variant="outlined"
              startIcon={<FilterOutlined />}
              onClick={() => setFilterOpen(true)}
            >
              Filters
            </Button>
            <IconButton onClick={(e) => setMenuAnchor(e.currentTarget)}>
              <EllipsisOutlined />
            </IconButton>
          </Stack>
        </Stack>

        <Menu anchorEl={menuAnchor} open={Boolean(menuAnchor)} onClose={() => setMenuAnchor(null)}>
          <MenuItem onClick={() => { setMenuAnchor(null); }}>Export CSV</MenuItem>
        </Menu>
      </Box>

      {/* ===== Table Section ===== */}
      <Box sx={{ p: 2, minHeight: '400px', display: 'flex', flexDirection: 'column' }}>
        {loading ? (
          <Stack alignItems="center" justifyContent="center" sx={{ flexGrow: 1 }}>
            <CircularProgress />
            <Typography sx={{ mt: 2 }}>Loading reports...</Typography>
          </Stack>
        ) : (
          <OrdersTable
            rows={Array.isArray(reports) ? reports : []}
            onRefresh={loadReports}
          />
        )}
      </Box>

      {/* ===== Filter Drawer ===== */}
      <Drawer anchor="right" open={filterOpen} onClose={() => setFilterOpen(false)}>
        <Box sx={{ width: 320, p: 3 }}>
          <Typography variant="h6" gutterBottom>Filter Reports</Typography>
          <Divider sx={{ mb: 3 }} />

          <Stack spacing={3}>
            <TextField select label="Status" value={filters.status} onChange={handleFilterChange('status')} fullWidth size="small">
              <MenuItem value="All">All Statuses</MenuItem>
              <MenuItem value="Pending">Pending</MenuItem>
              <MenuItem value="Verified">Verified</MenuItem>
              <MenuItem value="Resolved">Resolved</MenuItem>
            </TextField>

            <TextField select label="Severity" value={filters.severity} onChange={handleFilterChange('severity')} fullWidth size="small">
              <MenuItem value="All">All Severities</MenuItem>
              <MenuItem value="High">High</MenuItem>
              <MenuItem value="Medium">Medium</MenuItem>
              <MenuItem value="Low">Low</MenuItem>
            </TextField>

            <TextField type="date" label="From" InputLabelProps={{ shrink: true }} value={filters.fromDate} onChange={handleFilterChange('fromDate')} fullWidth size="small" />
            <TextField type="date" label="To" InputLabelProps={{ shrink: true }} value={filters.toDate} onChange={handleFilterChange('toDate')} fullWidth size="small" />

            <Button variant="contained" fullWidth onClick={() => setFilterOpen(false)}>
              Apply & Close
            </Button>
          </Stack>
        </Box>
      </Drawer>
    </Box>
  );
}