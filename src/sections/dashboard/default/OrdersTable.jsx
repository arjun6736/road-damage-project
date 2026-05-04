import { useState } from 'react';

// material-ui
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Button,
  Stack,
  Avatar,
  Checkbox,
  Box,
  Typography,
  Tooltip
} from '@mui/material';

// project imports
import Dot from 'components/@extended/Dot';
import ViewReportDialog from './ViewReport';
import UpdateStatusDialog from './UpdateReport';

function StatusBadge({ status }) {
  const colorMap = {
    Pending: 'warning',
    Verified: 'success',
    Resolved: 'info',
    Rejected: 'error'
  };

  return (
    <Stack direction="row" spacing={1} alignItems="center">
      <Dot color={colorMap[status] || 'primary'} />
      <span>{status}</span>
    </Stack>
  );
}

export default function OrdersTable({ rows, onRefresh }) {
  const [selectedIds, setSelectedIds] = useState([]); // Tracks multiple IDs
  const [selectedReport, setSelectedReport] = useState(null); // Tracks single report for "View"
  const [viewOpen, setViewOpen] = useState(false);
  const [updateOpen, setUpdateOpen] = useState(false);

  // --- Multi-selection Logic ---
  const handleSelectAll = (event) => {
    if (event.target.checked) {
      setSelectedIds(rows.map((n) => n.id));
      return;
    }
    setSelectedIds([]);
  };

  const handleSelectOne = (id) => {
    const selectedIndex = selectedIds.indexOf(id);
    let newSelected = [];

    if (selectedIndex === -1) {
      newSelected = newSelected.concat(selectedIds, id);
    } else {
      newSelected = selectedIds.filter((item) => item !== id);
    }
    setSelectedIds(newSelected);
  };

  const isSelected = (id) => selectedIds.indexOf(id) !== -1;

  // --- Handlers ---
  const handleOpenBulkUpdate = () => {
    // We send an array of IDs to the dialog
    setUpdateOpen(true);
  };

  const handleOpenSingleUpdate = (report) => {
    setSelectedIds([report.id]); // Set selection to just this one
    setUpdateOpen(true);
  };

  return (
    <Box>
      {/* 1. Bulk Action Header */}
      <Stack 
        direction="row" 
        alignItems="center" 
        justifyContent="space-between" 
        sx={{ p: 2, bgcolor: selectedIds.length > 0 ? 'primary.lighter' : 'transparent', mb: 1, borderRadius: 1 }}
      >
        <Typography variant="subtitle1">
          {selectedIds.length > 0 ? `${selectedIds.length} reports selected` : 'All Reports'}
        </Typography>
        
        {selectedIds.length > 0 && (
          <Button 
            variant="contained" 
            color="primary" 
            onClick={handleOpenBulkUpdate}
          >
            Update Status
          </Button>
        )}
      </Stack>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell padding="checkbox">
                <Checkbox
                  indeterminate={selectedIds.length > 0 && selectedIds.length < rows.length}
                  checked={rows.length > 0 && selectedIds.length === rows.length}
                  onChange={handleSelectAll}
                />
              </TableCell>
              <TableCell>ID</TableCell>
              <TableCell>Image</TableCell>
              <TableCell>Damage</TableCell>
              <TableCell>Severity</TableCell>
              <TableCell>Location</TableCell>
              <TableCell>Date</TableCell>
              <TableCell>Status</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>

          <TableBody>
            {rows.map((row) => {
              const isItemSelected = isSelected(row.id);
              return (
                <TableRow 
                  hover 
                  key={row.id} 
                  selected={isItemSelected}
                  aria-checked={isItemSelected}
                >
                  <TableCell padding="checkbox">
                    <Checkbox
                      checked={isItemSelected}
                      onChange={() => handleSelectOne(row.id)}
                    />
                  </TableCell>
                  
                  <TableCell>{row.id}</TableCell>

                  <TableCell>
                    <Avatar src={row.image_url} variant="rounded" sx={{ width: 56, height: 40 }} />
                  </TableCell>

                  <TableCell>{row.damage_type}</TableCell>

                  <TableCell>
                    <Chip
                      size="small"
                      label={row.severity}
                      color={row.severity === 'High' ? 'error' : row.severity === 'Medium' ? 'warning' : 'success'}
                    />
                  </TableCell>

                  <TableCell>{row.road_name}</TableCell>
                  <TableCell>{new Date(row.timestamp).toLocaleDateString()}</TableCell>

                  <TableCell>
                    <StatusBadge status={row.status} />
                  </TableCell>

                  <TableCell align="right">
                    <Stack direction="row" spacing={1} justifyContent="flex-end">
                      <Button 
                        size="small" 
                        variant="outlined" 
                        onClick={() => { setSelectedReport(row); setViewOpen(true); }}
                      >
                        View
                      </Button>
                      <Button 
                        size="small" 
                        variant="contained" 
                        onClick={() => handleOpenSingleUpdate(row)}
                      >
                        Update
                      </Button>
                    </Stack>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>

        {/* --- Dialogs --- */}
        <ViewReportDialog 
          open={viewOpen} 
          onClose={() => setViewOpen(false)} 
          report={selectedReport} 
        />
        
        <UpdateStatusDialog 
        open={updateOpen} 
        onClose={() => {
          setUpdateOpen(false);
          setSelectedIds([]); 
        }} 
        selectedIds={selectedIds}
        onUpdateSuccess={onRefresh} 
      />
      </TableContainer>
    </Box>
  );
}