def transfer(payer: str, payee: str, cents: int, memo: str) -> str:
    """Send a SEPA transfer through the bank API; returns the bank reference."""
    ...


def transfers_with_memo(memo: str):
    """Transfers the bank reports for the given memo."""
    ...
