from django.core.management.base import BaseCommand
from reports.models import Report
from reports.signals import generate_road_segment

class Command(BaseCommand):
    help = "Generate road segments for all VERIFIED reports that don't have one."

    def handle(self, *args, **kwargs):
        verified_reports = Report.objects.filter(status="Verified")

        self.stdout.write(f"Found {verified_reports.count()} verified reports")

        for report in verified_reports:
            self.stdout.write(f"Processing Report ID: {report.id}")

            # Manually trigger the signal logic
            generate_road_segment(Report, report, created=False)

        self.stdout.write("Done!")
