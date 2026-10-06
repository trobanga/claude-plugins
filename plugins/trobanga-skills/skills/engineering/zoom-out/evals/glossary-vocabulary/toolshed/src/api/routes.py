from src.stl.reconcile import reconcile


def get_reconciliation(request):
    return {"mismatches": reconcile(request.params["month"])}
