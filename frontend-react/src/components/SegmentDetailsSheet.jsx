import React, { useEffect, useState } from "react";
import axios from "axios";
// 1. Import is correct here
import { useNavigate } from "react-router-dom";
import {
  Box,
  Paper,
  Typography,
  Button,
  CircularProgress,
  IconButton,
  Chip,
  Divider,
} from "@mui/material";
import {
  Close as CloseIcon,
  ReportProblem as ReportIcon,
  ErrorOutline as ErrorIcon,
} from "@mui/icons-material";

export default function SegmentDetailsSheet({ segmentId, onClose }) {
  const [details, setDetails] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  // 2. FIX: Initialize the hook here!
  const navigate = useNavigate();

  // --- FETCH LOGIC ---
  useEffect(() => {
    if (!segmentId) return;
    let isMounted = true;

    const fetchDetails = async () => {
      setLoading(true);
      setError(false);
      try {
        const res = await axios.get(
          `https://routefixer.dpdns.org/api/segments/${segmentId}/details/`
        );
        if (isMounted) setDetails(res.data);
      } catch (err) {
        console.error("Error fetching details:", err);
        if (isMounted) setError(true);
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    fetchDetails();
    return () => { isMounted = false; };
  }, [segmentId]);

  // --- HELPERS ---
  const handleReportClick = () => {
    // 3. Now this works because 'navigate' is defined
    navigate('/reportstable', { 
      state: { segmentId: segmentId } 
    });
  };

  const getSeverityColor = (severity) => {
    switch (String(severity).toLowerCase()) {
      case "high": return "error";    
      case "medium": return "warning"; 
      case "low": return "success";   
      default: return "default";      
    }
  };

  return (
    <Paper
      elevation={4}
      sx={{
        position: "absolute",
        bottom: 0,
        left: 0,
        right: 0,
        zIndex: 10,
        borderTopLeftRadius: 24,
        borderTopRightRadius: 24,
        p: 3,
        bgcolor: "background.paper",
        maxHeight: "50vh",
        overflowY: "auto",
      }}
    >
      <IconButton
        onClick={onClose}
        sx={{ position: "absolute", top: 8, right: 8, color: "grey.500" }}
      >
        <CloseIcon />
      </IconButton>

      <Box display="flex" justifyContent="center" mb={2}>
        <Box
          sx={{
            width: 40,
            height: 4,
            bgcolor: "grey.300",
            borderRadius: 2,
          }}
        />
      </Box>

      {loading && (
        <Box display="flex" justifyContent="center" alignItems="center" height={150}>
          <CircularProgress />
        </Box>
      )}

      {!loading && error && (
        <Box display="flex" flexDirection="column" alignItems="center" py={2}>
          <ErrorIcon color="error" sx={{ fontSize: 48, mb: 1 }} />
          <Typography variant="h6" gutterBottom>
            Failed to load details
          </Typography>
          <Typography variant="body2" color="text.secondary" mb={2}>
            Segment ID: {segmentId}
          </Typography>
          <Button
            variant="contained"
            color="error"
            startIcon={<ReportIcon />}
            fullWidth
            onClick={handleReportClick}
          >
            Report Damage Anyway
          </Button>
        </Box>
      )}

      {!loading && !error && details && (
        <Box>
          <Box display="flex" alignItems="center" mb={1}>
            <Typography variant="subtitle1" fontWeight="bold" mr={1}>
              Max Severity:
            </Typography>
            <Chip
              label={(details.max_severity || "N/A").toUpperCase()}
              color={getSeverityColor(details.max_severity)}
              size="small"
              sx={{ fontWeight: "bold", color: "white" }}
            />
          </Box>

          <Typography variant="body1" gutterBottom>
            Total Reports: <strong>{details.total_reports}</strong>
          </Typography>

          <Typography variant="body1" gutterBottom>
            Average Score: <strong>{Number(details.avg_severity || 0).toFixed(2)}</strong>
          </Typography>

          <Typography variant="body2" color="text.secondary" mb={2}>
            Last Report: {new Date(details.last_report_date).toLocaleDateString()}
          </Typography>

          <Divider sx={{ my: 2 }} />

          <Typography variant="caption" color="text.secondary" fontStyle="italic" display="block" mb={2}>
            Road condition based on recent reports.
          </Typography>

          <Button
            variant="contained"
            color="primary"
            startIcon={<ReportIcon />}
            fullWidth
            size="large"
            onClick={handleReportClick}
            sx={{ borderRadius: 2, fontWeight: "bold" }}
          >
            Damage Reports
          </Button>
        </Box>
      )}
    </Paper>
  );
}