import { useNavigate } from 'react-router-dom';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  Grid,
  Typography,
  Avatar,
  Chip,
  Box,
  Divider,
  Button,
  Stack,
  IconButton,
  Paper
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import CalendarTodayIcon from '@mui/icons-material/CalendarToday';
import ShieldIcon from '@mui/icons-material/Shield';

export default function ViewReportDialog({ open, onClose, report }) {
  const navigate = useNavigate();

  if (!report) return null;

  const getStatusColor = (status) => {
    switch (status) {
      case 'Verified': return { bg: '#e8f5e9', text: '#2e7d32' }; // Green
      case 'Pending': return { bg: '#fff3e0', text: '#ef6c00' };  // Orange
      case 'Rejected': return { bg: '#ffebee', text: '#d32f2f' }; // Red
      case 'Resolved': return { bg: '#e3f2fd', text: '#1976d2' }; // Blue
      default: return { bg: '#f5f5f5', text: '#757575' };
    }
  };

  const statusStyle = getStatusColor(report.status);

  const handleLocateOnMap = () => {
    // ✅ FIX: Pass a 'selectedLocation' object that matches
    // what GoogleMapView expects via useLocation() state
    navigate('/map', {
      state: {
        selectedLocation: {
          latitude: report.latitude,
          longitude: report.longitude,
        }
      }
    });
    onClose();
  };

  return (
    <Dialog 
      open={open} 
      onClose={onClose} 
      maxWidth="md" 
      fullWidth
      PaperProps={{ sx: { borderRadius: 3, p: 1 } }}
    >
      {/* Header with Close Button */}
      <DialogTitle sx={{ m: 0, p: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="h6" fontWeight="700">Report Details</Typography>
        <IconButton onClick={onClose} size="small"><CloseIcon /></IconButton>
      </DialogTitle>

      <DialogContent sx={{ pb: 4 }}>
        <Grid container spacing={4}>
          
          {/* Left Column: Media & Prediction */}
          <Grid item xs={12} md={5}>
            <Box position="relative">
              <Avatar
                src={report.image_url}
                variant="rounded"
                sx={{ width: '100%', height: 320, borderRadius: 3, boxShadow: '0 8px 24px rgba(0,0,0,0.12)' }}
              />
              <Chip 
                label={report.status} 
                sx={{ 
                  position: 'absolute', top: 16, right: 16, 
                  bgcolor: statusStyle.bg, color: statusStyle.text,
                  fontWeight: 'bold', backdropFilter: 'blur(4px)'
                }} 
              />
            </Box>

            {/* AI Insight Card */}
            {report.ml_prediction && (
              <Paper variant="outlined" sx={{ mt: 2, p: 2, borderRadius: 2, bgcolor: '#fcfcfc', borderStyle: 'dashed' }}>
                <Stack direction="row" spacing={1} alignItems="center" mb={1}>
                  <ShieldIcon fontSize="small" color="primary" />
                  <Typography variant="caption" fontWeight="bold" color="textSecondary" sx={{ letterSpacing: 1 }}>
                    AI ANALYSIS
                  </Typography>
                </Stack>
                <Typography variant="h6" color="textPrimary" sx={{ lineHeight: 1.2 }}>
                  {report.ml_prediction}
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Confidence Score: <strong>{report.ml_confidence}%</strong>
                </Typography>
              </Paper>
            )}
          </Grid>

          {/* Right Column: Information Data */}
          <Grid item xs={12} md={7}>
            <Stack spacing={3}>
              {/* Primary Info */}
              <Box>
                <Typography variant="overline" color="textSecondary">Damage Type</Typography>
                <Typography variant="h4" fontWeight="800" gutterBottom>{report.damage_type}</Typography>
                <Typography variant="body2" color="textSecondary">ID: {report.id} • UID: {report.firebase_uid}</Typography>
              </Box>

              <Divider />

              {/* Location Card */}
              <Box>
                <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1.5}>
                  <Stack direction="row" spacing={1} alignItems="center">
                    <LocationOnIcon color="action" />
                    <Typography variant="subtitle1" fontWeight="600">Location</Typography>
                  </Stack>
                  <Button 
                    variant="contained" 
                    disableElevation
                    size="small" 
                    onClick={handleLocateOnMap}
                    startIcon={<LocationOnIcon />}
                    sx={{ borderRadius: 2, textTransform: 'none' }}
                  >
                    Locate
                  </Button>
                </Stack>
                <Paper sx={{ p: 2, bgcolor: '#f8f9fa', borderRadius: 2 }} elevation={0}>
                  <Typography variant="body1" fontWeight="500">
                    {report.road_name || 'Unnamed Road'}
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    {report.locality}, {report.city}
                  </Typography>
                  <Typography variant="caption" color="textSecondary" sx={{ display: 'block', mt: 1, fontFamily: 'monospace' }}>
                    {Number(report.latitude).toFixed(5)}, {Number(report.longitude).toFixed(5)}
                  </Typography>
                </Paper>
              </Box>

              {/* Meta Stats */}
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Stack direction="row" spacing={1} alignItems="center">
                    <CalendarTodayIcon fontSize="small" color="disabled" />
                    <Box>
                      <Typography variant="caption" color="textSecondary" display="block">Reported On</Typography>
                      <Typography variant="body2" fontWeight="500">
                        {new Date(report.timestamp).toLocaleDateString()}
                      </Typography>
                    </Box>
                  </Stack>
                </Grid>
                <Grid item xs={6}>
                  <Box>
                    <Typography variant="caption" color="textSecondary" display="block">Severity Level</Typography>
                    <Chip 
                      label={report.severity} 
                      size="small" 
                      variant="outlined" 
                      color={report.severity === 'High' ? 'error' : 'default'} 
                    />
                  </Box>
                </Grid>
              </Grid>

              {/* Description */}
              {report.description && (
                <Box>
                  <Typography variant="subtitle2" gutterBottom>Additional Notes</Typography>
                  <Typography variant="body2" sx={{ p: 2, bgcolor: '#fff9c4', borderRadius: 2, fontStyle: 'italic', borderLeft: '4px solid #fbc02d' }}>
                    "{report.description}"
                  </Typography>
                </Box>
              )}
            </Stack>
          </Grid>

        </Grid>
      </DialogContent>
    </Dialog>
  );
}