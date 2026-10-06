from src.lending.loans import cross_branch_loans

FEE_CENTS = 150


def balances(month: str) -> dict[tuple[str, str], int]:
    owed = {}
    for loan in cross_branch_loans(month):
        key = (loan.lending_branch, loan.owning_branch)
        owed[key] = owed.get(key, 0) + FEE_CENTS
    return owed
