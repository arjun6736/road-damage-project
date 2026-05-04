import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Typography,
  Box,
  CircularProgress
} from '@mui/material';
import axios from 'axios';

export default function UpdateStatusDialog({ open, onClose, selectedIds, onUpdateSuccess }) {
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(false);

  const handleUpdate = async () => {
  if (!status) return;
  setLoading(true);
  try {
    const response = await axios.post('http://localhost:8000/api/reports/bulk-update/', {
      report_ids: selectedIds,
      status: status
    });

    if (response.status === 200) {
      // 1. Trigger the data reload in the parent component
      if (onUpdateSuccess) {
        await onUpdateSuccess(); 
      }
      // 2. Close the dialog and reset local state
      handleClose();
    }
  } catch (error) {
    console.error("Failed to update reports:", error);
    alert("Error updating status.");
  } finally {
    setLoading(false);
  }
};

  const handleClose = () => {
    setStatus('');
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} fullWidth maxWidth="xs">
      <DialogTitle>
        Update Status 
        <Typography variant="caption" display="block" color="textSecondary">
          Targeting {selectedIds?.length || 0} selected report(s)
        </Typography>
      </DialogTitle>
      
      <DialogContent>
        <Box sx={{ mt: 2 }}>
          <FormControl fullWidth>
            <InputLabel id="status-select-label">New Status</InputLabel>
            <Select
              labelId="status-select-label"
              value={status}
              label="New Status"
              onChange={(e) => setStatus(e.target.value)}
              disabled={loading}
            >
              <MenuItem value="Pending">Pending</MenuItem>
              <MenuItem value="Verified">Verified</MenuItem>
              <MenuItem value="In-Process">In-Process</MenuItem>
              <MenuItem value="Resolved">Resolved</MenuItem>
              <MenuItem value="Rejected">Rejected</MenuItem>
            </Select>
          </FormControl>
        </Box>
      </DialogContent>

      <DialogActions sx={{ p: 2 }}>
        <Button onClick={handleClose} color="inherit" disabled={loading}>
          Cancel
        </Button>
        <Button 
          onClick={handleUpdate} 
          variant="contained" 
          disabled={!status || loading}
          startIcon={loading && <CircularProgress size={16} />}
        >
          {loading ? 'Updating...' : 'Confirm Update'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}