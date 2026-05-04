import {
  GoogleMap,
  LoadScript,
  Polyline,
  Marker,
} from "@react-google-maps/api";
import { useEffect, useState, useCallback, useRef } from "react";
import axios from "axios";
import { Box } from "@mui/material";
import SegmentDetailsSheet from "./SegmentDetailsSheet";

const containerStyle = {
  width: "100%",
  height: "100vh",
};

const defaultCenter = { lat: 11.2588, lng: 75.7804 };

export default function GoogleMapView({ selectedLocation }) {
  const [center, setCenter] = useState(defaultCenter);
  const [zoom, setZoom] = useState(13);
  const [segments, setSegments] = useState([]);
  const [selectedSegmentId, setSelectedSegmentId] = useState(null);
  const [pinLocation, setPinLocation] = useState(null); // ✅ Track pin marker

  const mapRef = useRef(null);
  const debounceTimer = useRef(null);

  // ✅ FIX: React to selectedLocation prop changes and fly to the location
  useEffect(() => {
    if (!selectedLocation) return;

    const lat = parseFloat(selectedLocation.latitude);
    const lng = parseFloat(selectedLocation.longitude);

    if (isNaN(lat) || isNaN(lng)) {
      console.warn("Invalid coordinates in selectedLocation:", selectedLocation);
      return;
    }

    const newCenter = { lat, lng };

    // Update center state and pan/zoom the map
    setCenter(newCenter);
    setPinLocation(newCenter); // ✅ Drop a pin at the report location

    if (mapRef.current) {
      mapRef.current.panTo(newCenter);
      mapRef.current.setZoom(17); // ✅ Zoom in close enough to see the pin
    }
  }, [selectedLocation]);

  // --- FETCHING LOGIC ---
  const fetchSegments = useCallback(async (lat, lng, zoomLevel) => {
    if (selectedSegmentId) return;

    if (debounceTimer.current) clearTimeout(debounceTimer.current);

    debounceTimer.current = setTimeout(async () => {
      try {
        const res = await axios.get(
          "https://routefixer.dpdns.org/api/road-segments/map/",
          { params: { lat, lng, zoom: Math.round(zoomLevel) } }
        );
        setSegments(Array.isArray(res.data) ? res.data : []);
      } catch (err) {
        console.error("API Error:", err);
      }
    }, 400);
  }, [selectedSegmentId]);

  // --- MAP HANDLERS ---
  const handleIdle = useCallback(() => {
    if (!mapRef.current) return;
    const c = mapRef.current.getCenter();
    const z = mapRef.current.getZoom();
    setZoom(z);
    fetchSegments(c.lat(), c.lng(), z);
  }, [fetchSegments]);

  // --- HELPERS ---
  const parsePolyline = (data) => {
    if (!data) return [];
    return data
      .split("|")
      .map((p) => {
        const [lat, lng] = p.split(",");
        return { lat: parseFloat(lat), lng: parseFloat(lng) };
      })
      .filter((p) => !isNaN(p.lat));
  };

  const getPolylineColor = (severity) => {
    switch (String(severity).toLowerCase()) {
      case "high":   return "#d32f2f";
      case "medium": return "#ed6c02";
      case "low":    return "#2e7d32";
      default:       return "#9e9e9e";
    }
  };

  return (
    <LoadScript googleMapsApiKey={import.meta.env.VITE_GOOGLE_MAPS_KEY}>
      <Box sx={{ position: "relative", height: "100vh", width: "100%" }}>
        <GoogleMap
          mapContainerStyle={containerStyle}
          center={center}
          zoom={zoom}
          onLoad={(map) => { mapRef.current = map; }}
          onIdle={handleIdle}
          onClick={() => {
            setSelectedSegmentId(null);
            setPinLocation(null); // ✅ Clear pin on map click
          }}
          options={{
            zoomControl: false,
            streetViewControl: false,
            mapTypeControl: false,
            fullscreenControl: false,
          }}
        >
          {/* ✅ Report location pin marker */}
          {pinLocation && (
            <Marker
              position={pinLocation}
              animation={2} // google.maps.Animation.DROP
              title="Report Location"
            />
          )}

          {segments.map((seg) => {
            const path = parsePolyline(seg.polyline_points);
            const isSelected = seg.id === selectedSegmentId;
            if (path.length < 2) return null;

            return (
              <Polyline
                key={seg.id}
                path={path}
                onClick={(e) => {
                  e.stop();
                  setSelectedSegmentId(seg.id);
                }}
                options={{
                  strokeColor: isSelected ? "#1976d2" : getPolylineColor(seg.max_severity),
                  strokeWeight: isSelected ? 8 : 5,
                  zIndex: isSelected ? 99 : 1,
                  clickable: true,
                }}
              />
            );
          })}
        </GoogleMap>

        {/* --- BOTTOM SHEET --- */}
        {selectedSegmentId && (
          <SegmentDetailsSheet
            segmentId={selectedSegmentId}
            onClose={() => setSelectedSegmentId(null)}
          />
        )}
      </Box>
    </LoadScript>
  );
}