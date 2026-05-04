from rest_framework import serializers
from .models import Report
from decimal import Decimal, InvalidOperation
from .models import RoadCaptureSegment


class ReportSerializer(serializers.ModelSerializer):
    # WRITEABLE field (used during POST)
    image = serializers.ImageField(write_only=True, required=False)

    # READ field (used during GET)
    image_url = serializers.SerializerMethodField(read_only=True)
    gps = serializers.CharField(write_only=True, required=True)

    latitude = serializers.DecimalField(max_digits=10, decimal_places=7, required=False)
    longitude = serializers.DecimalField(max_digits=10, decimal_places=7, required=False)

    class Meta:
        model = Report
        fields = (
            'id',
            'firebase_uid',
            'fcm_token',

            # 🖼 Image (ABSOLUTE URL)
            'image',
            'image_url',

            # Damage info
            'damage_type',
            'severity',
            'description',

            # GPS
            'latitude',
            'longitude',
            'gps',

            # Location metadata
            'road_name',
            'locality',
            'city',

            # ML output
            'ml_prediction',
            'ml_confidence',

            # Segment grouping
            'segment_id',

            # Workflow
            'status',
            'timestamp',
            'updated_at',
        )

        read_only_fields = (
            'id',
            'status',
            'timestamp',
            'updated_at',
            'road_name',
            'locality',
            'city',
            'ml_prediction',
            'ml_confidence',
        )

    #  ALWAYS return absolute image URL
    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image and request:
            url = request.build_absolute_uri(obj.image.url)
            print("image_Url:",url)
            return url
        return None

    def validate(self, data):
        gps_string = data.pop('gps', None)
        if not gps_string:
            raise serializers.ValidationError({"gps": "Required format: lat,lng"})

        try:
            lat_str, lng_str = gps_string.split(',', 1)
            data['latitude'] = Decimal(lat_str.strip())    #  ALWAYS return absolute image URL

            data['longitude'] = Decimal(lng_str.strip())
        except Exception:
            raise serializers.ValidationError({"gps": "Invalid GPS format"})

        return data



class RoadSegmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = RoadCaptureSegment
        fields = [
            "id",
            "polyline_points",
            "center_lat",
            "center_lng",
            "road_name",
            "locality",
            "city",
            "capture_time",
        ]

