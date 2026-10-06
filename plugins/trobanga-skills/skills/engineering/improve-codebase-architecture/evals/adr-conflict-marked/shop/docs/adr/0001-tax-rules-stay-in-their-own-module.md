# Tax rules stay in their own module

Finance owns `src/pricing/tax.py` and ships changes to it on the legal calendar, independent of our releases; their auditors review that file alone. We keep tax out of the pricing module even though pricing calls it on every Order, because merging them would put all of pricing under Finance's audit and release process.
