import { useTheme } from '@mui/material/styles';
import useMediaQuery from '@mui/material/useMediaQuery';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import CircularProgress from '@mui/material/CircularProgress';

import { BarChart } from '@mui/x-charts';
import MainCard from 'components/MainCard';

// ==============================|| DAMAGE SEVERITY CHART ||============================== //

export default function DamageSeverityChart({ high = 0, medium = 0, low = 0, isLoading }) {
  const theme = useTheme();
  const downSM = useMediaQuery(theme.breakpoints.down('sm'));

  // Labels must match backend severity types
  const labels = ['Low', 'Medium', 'High'];
  const severityData = [low, medium, high];

  return (
    <MainCard sx={{ mt: 1 }} content={false}>
      <Box sx={{ p: 2.5 }}>
        <Stack sx={{ mb: 2 }}>
          <Typography variant="body2" color="text.secondary">
            Overview of reported road damage severity
          </Typography>
        </Stack>

        {isLoading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
            <CircularProgress />
          </Box>
        ) : (
          <BarChart
            height={360}
            grid={{ horizontal: true }}
            xAxis={[
              {
                data: labels,
                scaleType: 'band',
                categoryGapRatio: downSM ? 0.5 : 0.7
              }
            ]}
            yAxis={[
              {
                label: 'Number of Reports',
                tickMinStep: 1
              }
            ]}
            series={[
              {
                data: severityData
              }
            ]}
            slotProps={{
              bar: { rx: 6, ry: 6 },
              tooltip: { trigger: 'item' }
            }}
            margin={{ top: 20, left: 60, bottom: 40, right: 20 }}
            sx={{
              '& .MuiChartsGrid-line': {
                strokeDasharray: '4 4',
                stroke: theme.vars.palette.divider
              }
            }}
          />
        )}
      </Box>
    </MainCard>
  );
}
