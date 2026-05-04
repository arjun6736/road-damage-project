// pages/MapPage.jsx  (or wherever your /map route renders)
import { useLocation } from 'react-router-dom';
import GoogleMapView from 'components/GoogleMapView'; // adjust path as needed

export default function MapPage() {
  const location = useLocation();

  // ✅ Pull selectedLocation out of router state (set by ViewReportDialog)
  const selectedLocation = location.state?.selectedLocation || null;

  return <GoogleMapView selectedLocation={selectedLocation} />;
}