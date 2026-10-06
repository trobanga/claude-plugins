from src.ledger.ledger import balances
from src.payouts.bank import transfers_with_memo


def reconcile(month: str) -> list[str]:
    """Return the Branch pairs whose bank transfers don't match the Ledger."""
    sent = {(t.payer, t.payee): t.cents for t in transfers_with_memo(f"stl {month}")}
    owed = balances(month)
    return [f"{a}->{b}" for (a, b), cents in owed.items() if sent.get((a, b), 0) != cents]
