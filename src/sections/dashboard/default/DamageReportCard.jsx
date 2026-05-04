import { useState } from 'react';

// material-ui
import Grid from '@mui/material/Grid';
import MenuItem from '@mui/material/MenuItem';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';

// project imports
import DamageSeverityChart from '../DamageSeverityChart';

// filter options
const statusOptions = [
  { value: 'today', label: 'Today' },
  { value: 'month', label: 'This Month' },
  { value: 'year', label: 'This Year' }
];

// ==============================|| DAMAGE REPORT CARD ||============================== //

export default function DamageReportCard({ high, medium, low, isLoading }) {
  const [filter, setFilter] = useState('today');

  return (
    <>
      <Grid container sx={{ alignItems: 'center', justifyContent: 'space-between' }}>
        <Grid>
          <Typography variant="h5">Damage Reports Overview</Typography>
        </Grid>
        <Grid>
          <TextField
            size="small"
            select
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            sx={{ minWidth: 120 }}
          >
            {statusOptions.map((option) => (
              <MenuItem key={option.value} value={option.value}>
                {option.label}
              </MenuItem>
            ))}
          </TextField>
        </Grid>
      </Grid>

      <DamageSeverityChart
        high={high}
        medium={medium}
        low={low}
        isLoading={isLoading}
      />
    </>
  );
}
