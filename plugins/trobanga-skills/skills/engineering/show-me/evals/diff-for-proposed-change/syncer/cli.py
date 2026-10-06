import argparse

from commands import run_sync, run_status


def main():
    p = argparse.ArgumentParser(prog="syncer")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("sync")
    sub.add_parser("status")
    args = p.parse_args()
    {"sync": run_sync, "status": run_status}[args.cmd]()


if __name__ == "__main__":
    main()
