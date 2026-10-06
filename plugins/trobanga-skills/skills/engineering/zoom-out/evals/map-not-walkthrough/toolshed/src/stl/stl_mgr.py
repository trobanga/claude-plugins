from src.ledger.ledger import balances
from src.payouts.bank import transfer


class StlMgr:
    def run(self, month: str) -> list[str]:
        refs = []
        for (payer, payee), cents in self._net_positions(balances(month)).items():
            refs.append(transfer(payer, payee, cents, memo=f"stl {month}"))
        return refs

    def _net_positions(self, owed: dict[tuple[str, str], int]) -> dict[tuple[str, str], int]:
        net = {}
        for (a, b), cents in owed.items():
            back = owed.get((b, a), 0)
            if cents > back:
                net[(a, b)] = cents - back
            elif cents == back:
                continue
            # the larger side of each pair is kept; equal pairs cancel out
        return {k: v for k, v in net.items() if v >= 100}  # bank rejects transfers under 1 EUR
