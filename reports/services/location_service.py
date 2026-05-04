import time
import googlemaps
from django.conf import settings

# Initialize client
gmaps = googlemaps.Client(key=settings.GOOGLE_ROADS_API_KEY)

def get_snapped_location(lat, lon):
    """
    1. Snaps the raw GPS to the nearest road segment.
    2. Reverse geocodes that EXACT point to get the road name.
    3. Retries 3 times if the connection fails.
    """
    if not lat or not lon:
        return None

    max_retries = 3
    
    for attempt in range(max_retries):
        try:
            # --- STEP 1: SNAP TO ROAD ---
            # "nearest_roads" finds the closest road segment to the point
            snapped_result = gmaps.nearest_roads((lat, lon))

            if not snapped_result:
                print(" No nearby road found to snap to.")
                # Fallback: Use original coords if snapping fails
                snapped_lat, snapped_lon = lat, lon
            else:
                # Take the closest result (index 0)
                location = snapped_result[0]['location']
                snapped_lat = location['latitude']
                snapped_lon = location['longitude']
                print(f" GPS Snapped: ({lat}, {lon}) -> ({snapped_lat}, {snapped_lon})")

            # --- STEP 2: REVERSE GEOCODE (Using Snapped Coords) ---
            reverse_result = gmaps.reverse_geocode((snapped_lat, snapped_lon))

            if not reverse_result:
                return None

            # Parse the first (most accurate) result
            address_comps = reverse_result[0]['address_components']
            
            # Helper function to extract Google address components
            def get_component(type_name):
                for comp in address_comps:
                    if type_name in comp['types']:
                        return comp['long_name']
                return ""

            # If we succeed, return the data immediately (exit the loop)
            return {
                "snapped_lat": snapped_lat,
                "snapped_lon": snapped_lon,
                "road_name": get_component('route'),
                "locality": get_component('sublocality') or get_component('sublocality_level_1'),
                "city": get_component('locality') or get_component('administrative_area_level_2'),
            }

        except Exception as e:
            print(f" Attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                print(" Retrying in 2 seconds...")
                time.sleep(2)  # Wait 2 seconds before retrying
            else:
                print(" All attempts failed. Connection issue.")
                return None