import importlib

# Jobs are looked up by name from the scheduler config (jobs.yaml).
JOBS = {
    "month-end-settlement": "src.stl.stl_mgr:StlMgr.run",
    "post-settlement-check": "src.stl.reconcile:reconcile",
}


def resolve(name: str):
    module, attr = JOBS[name].split(":")
    target = importlib.import_module(module)
    for part in attr.split("."):
        target = getattr(target, part)
    return target
