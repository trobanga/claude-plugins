import datetime

from src.stl.reconcile import reconcile


def main():
    last_month = (datetime.date.today().replace(day=1) - datetime.timedelta(days=1)).strftime("%Y-%m")
    mismatches = reconcile(last_month)
    if mismatches:
        print("RECONCILIATION FAILED:", ", ".join(mismatches))
