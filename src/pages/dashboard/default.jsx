import { useEffect, useState ,useCallback } from 'react';

// material-ui
import Grid from '@mui/material/Grid';
import IconButton from '@mui/material/IconButton';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import Typography from '@mui/material/Typography';
import CircularProgress from '@mui/material/CircularProgress';
import Box from '@mui/material/Box';
// project imports
import MainCard from 'components/MainCard';
import AnalyticEcommerce from 'components/cards/statistics/AnalyticEcommerce';
import OrdersTable from 'sections/dashboard/default/OrdersTable';
import DamageReportCard from '../../sections/dashboard/default/DamageReportCard';

// api
import { fetchDashboardStats } from 'api/reports';

// assets
import EllipsisOutlined from '@ant-design/icons/EllipsisOutlined';

// ==============================|| DASHBOARD - DEFAULT ||============================== //

export default function DashboardDefault() {
  const [orderMenuAnchor, setOrderMenuAnchor] = useState(null);

  // Dashboard data state
  const [stats, setStats] = useState(null);
  const [recentReports, setRecentReports] = useState([]);
  const [severity, setSeverity] = useState({ high: 0, medium: 0, low: 0 });
  const [loading, setLoading] = useState(true);

  const handleOrderMenuClick = (event) => setOrderMenuAnchor(event.currentTarget);
  const handleOrderMenuClose = () => setOrderMenuAnchor(null);

  // ================= Fetch Dashboard Stats =================
  const loadDashboard = useCallback(async () => {
    try {
      setLoading(true);
      const res = await fetchDashboardStats();
      setStats(res.data.stats);
      setRecentReports(res.data.recent_reports);
      setSeverity({
        high: res.data.severity_graph.High || 0,
        medium: res.data.severity_graph.Medium || 0,
        low: res.data.severity_graph.Low || 0
      });
    } catch (error) {
      console.error('Dashboard API Error:', error);
    } finally {
      setLoading(false);
    }
  }, []);
  useEffect(() => {
    loadDashboard();
  }, [loadDashboard]);

  // ================= UI =================
  return (
    <Grid container rowSpacing={4.5} columnSpacing={2.75}>
      {/* Header */}
      <Grid size={12}>
        <Typography variant="h4">Admin Dashboard</Typography>
      </Grid>

      {/* KPI Cards */}
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <AnalyticEcommerce title="Total Reports" count={loading ? '...' : stats?.total} />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <AnalyticEcommerce title="Resolved" count={loading ? '...' : stats?.resolved} color="success" />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <AnalyticEcommerce title="Pending" count={loading ? '...' : stats?.pending} color="warning" />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <AnalyticEcommerce title="In Progress" count={loading ? '...' : stats?.in_progress} color="info" />
      </Grid>
      
      {/* Severity Analytics */}
      <Grid size={{ xs: 12, lg: 8 }}>
        <DamageReportCard high={severity.high} medium={severity.medium} low={severity.low} isLoading={loading} />
      </Grid>

      {/* Recent Reports Section */}
      <Grid size={12}>
        <Grid container alignItems="center" justifyContent="space-between">
          <Typography variant="h5">Recent Reports</Typography>

          <IconButton onClick={handleOrderMenuClick}>
            <EllipsisOutlined />
          </IconButton>

          <Menu anchorEl={orderMenuAnchor} open={Boolean(orderMenuAnchor)} onClose={handleOrderMenuClose}>
            <MenuItem onClick={handleOrderMenuClose}>Export CSV</MenuItem>
            <MenuItem onClick={handleOrderMenuClose}>Export Excel</MenuItem>
            <MenuItem onClick={handleOrderMenuClose}>Print</MenuItem>
          </Menu>
        </Grid>

        <MainCard sx={{ mt: 2 }} content={false}>
          {loading ? (
            <Box sx={{ p: 5, textAlign: 'center' }}>
              <CircularProgress size={26} />
            </Box>
          ) : (
            <OrdersTable rows={recentReports} onRefresh={loadDashboard}/>
          )}
        </MainCard>
      </Grid>
    </Grid>
  );
}
